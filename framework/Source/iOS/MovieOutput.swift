import AVFoundation

public protocol AudioEncodingTarget {
    func activateAudioTrack()
    func processAudioBuffer(sampleBuffer:CMSampleBuffer)
}

public class MovieOutput: ImageConsumer, AudioEncodingTarget {
    public let sources = SourceContainer()
    public let maximumInputs:UInt = 1
    
    let assetWriter:AVAssetWriter
    let assetWriterVideoInput:AVAssetWriterInput
    var assetWriterAudioInput:AVAssetWriterInput?

    let assetWriterPixelBufferInput:AVAssetWriterInputPixelBufferAdaptor
    let size:Size
    let colorSwizzlingShader:ShaderProgram
    private var isRecording = false
    private var videoEncodingIsFinished = false
    private var audioEncodingIsFinished = false
    private var startTime:CMTime?
    private var previousFrameTime = kCMTimeNegativeInfinity
    private var previousAudioTime = kCMTimeNegativeInfinity
    private var encodingLiveVideo:Bool
    var pixelBuffer:CVPixelBuffer? = nil
    var renderFramebuffer:Framebuffer!
    
    public init(URL:NSURL, size:Size, fileType:String = AVFileTypeQuickTimeMovie, liveVideo:Bool = false, settings:[String:AnyObject]? = nil) throws {
        if sharedImageProcessingContext.supportsTextureCaches() {
            self.colorSwizzlingShader = sharedImageProcessingContext.passthroughShader
        } else {
            self.colorSwizzlingShader = crashOnShaderCompileFailure("MovieOutput"){try sharedImageProcessingContext.programForVertexShader(defaultVertexShaderForInputs(1), fragmentShader:ColorSwizzlingFragmentShader)}
        }
        
        self.size = size
        assetWriter = try AVAssetWriter(URL:URL, fileType:fileType)
        // Set this to make sure that a functional movie is produced, even if the recording is cut off mid-stream. Only the last second should be lost in that case.
        assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, 1000)
        
        var localSettings:[String:AnyObject]
        if let settings = settings {
            localSettings = settings
        } else {
            localSettings = [String:AnyObject]()
        }
        
        localSettings[AVVideoWidthKey] = localSettings[AVVideoWidthKey] ?? NSNumber(float:size.width)
        localSettings[AVVideoHeightKey] = localSettings[AVVideoHeightKey] ?? NSNumber(float:size.height)
        localSettings[AVVideoCodecKey] =  localSettings[AVVideoCodecKey] ?? AVVideoCodecH264
        
        assetWriterVideoInput = AVAssetWriterInput(mediaType:AVMediaTypeVideo, outputSettings:localSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = liveVideo
        encodingLiveVideo = liveVideo
        
        // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
        let sourcePixelBufferAttributesDictionary:[String:AnyObject] = [kCVPixelBufferPixelFormatTypeKey as String:NSNumber(int:Int32(kCVPixelFormatType_32BGRA)),
                                                                        kCVPixelBufferWidthKey as String:NSNumber(float:size.width),
                                                                        kCVPixelBufferHeightKey as String:NSNumber(float:size.height)]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:assetWriterVideoInput, sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary)
        assetWriter.addInput(assetWriterVideoInput)
    }
    
    public func startRecording() {
        startTime = nil
        sharedImageProcessingContext.runOperationSynchronously{
            self.isRecording = self.assetWriter.startWriting()
            
            CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput.pixelBufferPool!, &self.pixelBuffer)
            
            /* AVAssetWriter will use BT.601 conversion matrix for RGB to YCbCr conversion
             * regardless of the kCVImageBufferYCbCrMatrixKey value.
             * Tagging the resulting video file as BT.601, is the best option right now.
             * Creating a proper BT.709 video is not possible at the moment.
             */
            CVBufferSetAttachment(self.pixelBuffer!, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate)
            CVBufferSetAttachment(self.pixelBuffer!, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_601_4, kCVAttachmentMode_ShouldPropagate)
            CVBufferSetAttachment(self.pixelBuffer!, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate)
            
            let bufferSize = GLSize(self.size)
            var cachedTextureRef:CVOpenGLESTextureRef? = nil
            let _ = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, sharedImageProcessingContext.coreVideoTextureCache, self.pixelBuffer!, nil, GLenum(GL_TEXTURE_2D), GL_RGBA, bufferSize.width, bufferSize.height, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), 0, &cachedTextureRef)
            let cachedTexture = CVOpenGLESTextureGetName(cachedTextureRef!)
            
            self.renderFramebuffer = try! Framebuffer(context:sharedImageProcessingContext, orientation:.Portrait, size:bufferSize, textureOnly:false, overriddenTexture:cachedTexture)
        }
    }
    
    public func finishRecording(completionCallback:(() -> Void)? = nil) {
        sharedImageProcessingContext.runOperationSynchronously{
            self.isRecording = false
            
            if (self.assetWriter.status == .Completed || self.assetWriter.status == .Cancelled || self.assetWriter.status == .Unknown) {
                sharedImageProcessingContext.runOperationAsynchronously{
                    completionCallback?()
                }
                return
            }
            if ((self.assetWriter.status == .Writing) && (!self.videoEncodingIsFinished)) {
                self.videoEncodingIsFinished = true
                self.assetWriterVideoInput.markAsFinished()
            }
            if ((self.assetWriter.status == .Writing) && (!self.audioEncodingIsFinished)) {
                self.audioEncodingIsFinished = true
                self.assetWriterAudioInput?.markAsFinished()
            }
            
            // Why can't I use ?? here for the callback?
            if let callback = completionCallback {
                self.assetWriter.finishWritingWithCompletionHandler(callback)
            } else {
                self.assetWriter.finishWritingWithCompletionHandler{}
                
            }
        }
    }
    
    public func newFramebufferAvailable(framebuffer:Framebuffer, fromSourceIndex:UInt) {
        defer {
            framebuffer.unlock()
        }
        guard isRecording else { return }
        // Ignore still images and other non-video updates (do I still need this?)
        guard let frameTime = framebuffer.timingStyle.timestamp?.asCMTime else { return }
        // If two consecutive times with the same value are added to the movie, it aborts recording, so I bail on that case
        guard (frameTime != previousFrameTime) else { return }
        
        if (startTime == nil) {
            if (assetWriter.status != .Writing) {
                assetWriter.startWriting()
            }
            
            assetWriter.startSessionAtSourceTime(frameTime)
            startTime = frameTime
        }
        
        // TODO: Run the following on an internal movie recording dispatch queue, context
        guard (assetWriterVideoInput.readyForMoreMediaData || (!encodingLiveVideo)) else {
            debugPrint("Had to drop a frame at time \(frameTime)")
            return
        }
        
        if !sharedImageProcessingContext.supportsTextureCaches() {
            let pixelBufferStatus = CVPixelBufferPoolCreatePixelBuffer(nil, assetWriterPixelBufferInput.pixelBufferPool!, &pixelBuffer)
            guard ((pixelBuffer != nil) && (pixelBufferStatus == kCVReturnSuccess)) else { return }
        }
        
        renderIntoPixelBuffer(pixelBuffer!, framebuffer:framebuffer)
        
        if (!assetWriterPixelBufferInput.appendPixelBuffer(pixelBuffer!, withPresentationTime:frameTime)) {
            debugPrint("Problem appending pixel buffer at time: \(frameTime)")
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, 0)
        if !sharedImageProcessingContext.supportsTextureCaches() {
            pixelBuffer = nil
        }
    }
    
    func renderIntoPixelBuffer(pixelBuffer:CVPixelBuffer, framebuffer:Framebuffer) {
        if !sharedImageProcessingContext.supportsTextureCaches() {
            renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:framebuffer.orientation, size:GLSize(self.size))
            renderFramebuffer.lock()
        }
        
        renderFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(Color.Black)
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        renderQuadWithShader(colorSwizzlingShader, uniformSettings:ShaderUniformSettings(), vertices:standardImageVertices, inputTextures:[framebuffer.texturePropertiesForOutputRotation(.NoRotation)])
        
        if sharedImageProcessingContext.supportsTextureCaches() {
            glFinish()
        } else {
            glReadPixels(0, 0, renderFramebuffer.size.width, renderFramebuffer.size.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddress(pixelBuffer))
            renderFramebuffer.unlock()
        }
    }
    
    // MARK: -
    // MARK: Audio support

    public func activateAudioTrack() {
        // TODO: Add ability to set custom output settings
        assetWriterAudioInput = AVAssetWriterInput(mediaType:AVMediaTypeAudio, outputSettings:nil)
        assetWriter.addInput(assetWriterAudioInput!)
        assetWriterAudioInput?.expectsMediaDataInRealTime = encodingLiveVideo
    }
    
    public func processAudioBuffer(sampleBuffer:CMSampleBuffer) {
        guard let assetWriterAudioInput = assetWriterAudioInput else { return }
        
        sharedImageProcessingContext.runOperationSynchronously{
            let currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            if (self.startTime == nil) {
                if (self.assetWriter.status != .Writing) {
                    self.assetWriter.startWriting()
                }
                
                self.assetWriter.startSessionAtSourceTime(currentSampleTime)
                self.startTime = currentSampleTime
            }
            
            guard (assetWriterAudioInput.readyForMoreMediaData || (!self.encodingLiveVideo)) else {
                return
            }
            
            if (!assetWriterAudioInput.appendSampleBuffer(sampleBuffer)) {
                print("Trouble appending audio sample buffer")
            }
        }
    }
}


public extension Timestamp {
    public init(_ time:CMTime) {
        self.value = time.value
        self.timescale = time.timescale
        self.flags = TimestampFlags(rawValue:time.flags.rawValue)
        self.epoch = time.epoch
    }
    
    public var asCMTime:CMTime {
        get {
            return CMTimeMakeWithEpoch(value, timescale, epoch)
        }
    }
}