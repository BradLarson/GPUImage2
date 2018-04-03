import AVFoundation

public protocol AudioEncodingTarget {
    func activateAudioTrack()
    func processAudioBuffer(_ sampleBuffer:CMSampleBuffer, shouldInvalidateSampleWhenDone:Bool)
    // Note: This is not used for synchronized encoding.
    func readyForNextAudioBuffer() -> Bool
}

public enum MovieOutputError: Error, CustomStringConvertible {
    case startWritingError(assetWriterError: Error?)
    case pixelBufferPoolNilError
    
    public var errorDescription: String {
        switch self {
        case .startWritingError(let assetWriterError):
            return "Could not start asset writer: \(String(describing: assetWriterError))"
        case .pixelBufferPoolNilError:
            return "Asset writer pixel buffer pool was nil. Make sure that your output file doesn't already exist."
        }
    }
    
    public var description: String {
        return "<\(type(of: self)): errorDescription = \(self.errorDescription)>"
    }
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
    var videoEncodingIsFinished = false
    var audioEncodingIsFinished = false
    private var previousFrameTime: CMTime?
    var encodingLiveVideo:Bool {
        didSet {
            assetWriterVideoInput.expectsMediaDataInRealTime = encodingLiveVideo
            assetWriterAudioInput?.expectsMediaDataInRealTime = encodingLiveVideo
        }
    }
    var pixelBuffer:CVPixelBuffer? = nil
    var renderFramebuffer:Framebuffer!
    
    var audioSettings:[String:Any]? = nil
    var audioSourceFormatHint:CMFormatDescription?
    
    let movieProcessingContext:OpenGLContext
    
    var synchronizedEncodingDebug = false
    var totalFramesAppended:Int = 0
    
    public init(URL:Foundation.URL, size:Size, fileType:String = AVFileTypeQuickTimeMovie, liveVideo:Bool = false, videoSettings:[String:Any]? = nil, videoNaturalTimeScale:CMTimeScale? = nil, audioSettings:[String:Any]? = nil, audioSourceFormatHint:CMFormatDescription? = nil) throws {
        imageProcessingShareGroup = sharedImageProcessingContext.context.sharegroup
        let movieProcessingContext = OpenGLContext()
        
        if movieProcessingContext.supportsTextureCaches() {
            self.colorSwizzlingShader = movieProcessingContext.passthroughShader
        } else {
            self.colorSwizzlingShader = crashOnShaderCompileFailure("MovieOutput"){try movieProcessingContext.programForVertexShader(defaultVertexShaderForInputs(1), fragmentShader:ColorSwizzlingFragmentShader)}
        }
        
        self.size = size
        
        assetWriter = try AVAssetWriter(url:URL, fileType:fileType)
        
        var localSettings:[String:Any]
        if let videoSettings = videoSettings {
            localSettings = videoSettings
        } else {
            localSettings = [String:Any]()
        }
        
        localSettings[AVVideoWidthKey] = localSettings[AVVideoWidthKey] ?? size.width
        localSettings[AVVideoHeightKey] = localSettings[AVVideoHeightKey] ?? size.height
        localSettings[AVVideoCodecKey] =  localSettings[AVVideoCodecKey] ?? AVVideoCodecH264
        
        assetWriterVideoInput = AVAssetWriterInput(mediaType:AVMediaTypeVideo, outputSettings:localSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = liveVideo
        
        // You should provide a naturalTimeScale if you have one for the current media.
        // Otherwise the asset writer will choose one for you and it may result in misaligned frames.
        if let naturalTimeScale = videoNaturalTimeScale {
            assetWriter.movieTimeScale = naturalTimeScale
            assetWriterVideoInput.mediaTimeScale = naturalTimeScale
            // This is set to make sure that a functional movie is produced, even if the recording is cut off mid-stream. Only the last second should be lost in that case.
            assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1, naturalTimeScale)
        }
        else {
            assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1, 1000)
        }
        
        encodingLiveVideo = liveVideo
        
        // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
        let sourcePixelBufferAttributesDictionary:[String:Any] = [kCVPixelBufferPixelFormatTypeKey as String:Int32(kCVPixelFormatType_32BGRA),
                                                                        kCVPixelBufferWidthKey as String:self.size.width,
                                                                        kCVPixelBufferHeightKey as String:self.size.height]
        
        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:assetWriterVideoInput, sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary)
        assetWriter.add(assetWriterVideoInput)
        
        self.audioSettings = audioSettings
        self.audioSourceFormatHint = audioSourceFormatHint
        
        self.movieProcessingContext = movieProcessingContext
    }
    
    public func startRecording(_ completionCallback:((_ started: Bool, _ error: Error?) -> Void)? = nil) {
        // Don't do this work on the movieProcessingContext queue so we don't block it.
        // If it does get blocked framebuffers will pile up from live video and after it is no longer blocked (this work has finished)
        // we will be able to accept framebuffers but the ones that piled up will come in too quickly resulting in most being dropped.
        DispatchQueue.global(qos: .utility).async {
            do {
                var success = false
                try NSObject.catchException {
                    success = self.assetWriter.startWriting()
                }
                
                if(!success) {
                    throw MovieOutputError.startWritingError(assetWriterError: self.assetWriter.error)
                }
                
                guard self.assetWriterPixelBufferInput.pixelBufferPool != nil else {
                    /*
                    When the pixelBufferPool returns nil, check the following:
                    1. the the output file of the AVAssetsWriter doesn't exist.
                    2. use the pixelbuffer after calling startSessionAtTime: on the AVAssetsWriter.
                    3. the settings of AVAssetWriterInput and AVAssetWriterInputPixelBufferAdaptor are correct.
                    4. the present times of appendPixelBuffer uses are not the same.
                    https://stackoverflow.com/a/20110179/1275014
                    */
                    throw MovieOutputError.pixelBufferPoolNilError
                }
                    
                self.isRecording = true
                
                self.synchronizedEncodingDebugPrint("MovieOutput started writing")
                
                completionCallback?(true, nil)
            } catch {
                self.assetWriter.cancelWriting()
                
                completionCallback?(false, error)
            }
        }
    }
    
    public func finishRecording(_ completionCallback:(() -> Void)? = nil) {
        movieProcessingContext.runOperationAsynchronously{
            guard self.isRecording,
                self.assetWriter.status == .writing else {
                    completionCallback?()
                    return
            }
            
            self.audioEncodingIsFinished = true
            self.videoEncodingIsFinished = true
            
            self.isRecording = false
            
            if let lastFrame = self.previousFrameTime {
                // Resolve black frames at the end. Without this the end timestamp of the session's samples could be either video or audio.
                // Documentation: "You do not need to call this method; if you call finishWriting without
                // calling this method, the session's effective end time will be the latest end timestamp of
                // the session's samples (that is, no samples will be edited out at the end)."
                self.assetWriter.endSession(atSourceTime: lastFrame)
            }
            
            self.assetWriter.finishWriting {
                completionCallback?()
            }
            self.synchronizedEncodingDebugPrint("MovieOutput finished writing")
            self.synchronizedEncodingDebugPrint("MovieOutput total frames appended: \(self.totalFramesAppended)")
        }
    }
    
    public func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        glFinish();
        
        let work = {
            guard self.isRecording,
                self.assetWriter.status == .writing,
                !self.videoEncodingIsFinished else {
                    self.synchronizedEncodingDebugPrint("Guard fell through, dropping frame")
                    return
            }
            
            // Ignore still images and other non-video updates (do I still need this?)
            guard let frameTime = framebuffer.timingStyle.timestamp?.asCMTime else { return }
            
            // If two consecutive times with the same value are added to the movie, it aborts recording, so I bail on that case.
            guard (frameTime != self.previousFrameTime) else { return }
            
            if (self.previousFrameTime == nil) {
                // This resolves black frames at the beginning. Any samples recieved before this time will be edited out.
                self.assetWriter.startSession(atSourceTime: frameTime)
            }
            
            self.previousFrameTime = frameTime

            guard (self.assetWriterVideoInput.isReadyForMoreMediaData || !self.encodingLiveVideo) else {
                print("Had to drop a frame at time \(frameTime)")
                return
            }
            
            while(!self.assetWriterVideoInput.isReadyForMoreMediaData && !self.encodingLiveVideo && !self.videoEncodingIsFinished) {
                self.synchronizedEncodingDebugPrint("Video waiting...")
                // Better to poll isReadyForMoreMediaData often since when it does become true
                // we don't want to risk letting framebuffers pile up in between poll intervals.
                usleep(100000) // 0.1 seconds
            }
            
            let pixelBufferStatus = CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput.pixelBufferPool!, &self.pixelBuffer)
            guard ((self.pixelBuffer != nil) && (pixelBufferStatus == kCVReturnSuccess)) else {
                print("WARNING: Unable to create pixel buffer, dropping frame")
                return
            }
            
            do {
                try self.renderIntoPixelBuffer(self.pixelBuffer!, framebuffer:framebuffer)
                
                self.synchronizedEncodingDebugPrint("Process frame output")
                
                try NSObject.catchException {
                    if (!self.assetWriterPixelBufferInput.append(self.pixelBuffer!, withPresentationTime:frameTime)) {
                        print("WARNING: Trouble appending pixel buffer at time: \(frameTime) \(String(describing: self.assetWriter.error))")
                    }
                }
            }
            catch {
                print("WARNING: Trouble appending pixel buffer at time: \(frameTime) \(error)")
            }
            
            if(self.synchronizedEncodingDebug) {
                self.totalFramesAppended += 1
            }
            
            CVPixelBufferUnlockBaseAddress(self.pixelBuffer!, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
            self.pixelBuffer = nil
            
            sharedImageProcessingContext.runOperationAsynchronously {
                framebuffer.unlock()
            }
        }

        if(self.encodingLiveVideo) {
            // This is done asynchronously to reduce the amount of work done on the sharedImageProcessingContext que
            // so we can decrease the risk of frames being dropped by the camera. I believe it is unlikely a backlog of framebuffers will occur
            // since the framebuffers come in much slower than during synchronized encoding.
            movieProcessingContext.runOperationAsynchronously(work)
        }
        else {
            // This is done synchronously to prevent framebuffers from piling up during synchronized encoding.
            // If we don't force the sharedImageProcessingContext queue to wait for this frame to finish processing it will
            // keep sending frames whenever isReadyForMoreMediaData = true but the movieProcessingContext queue would run when the system wants it to.
            movieProcessingContext.runOperationSynchronously(work)
        }
    }
    
    func renderIntoPixelBuffer(_ pixelBuffer:CVPixelBuffer, framebuffer:Framebuffer) throws {
        // Is this the first pixel buffer we have recieved?
        if(renderFramebuffer == nil) {
            CVBufferSetAttachment(pixelBuffer, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, .shouldPropagate)
            CVBufferSetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_601_4, .shouldPropagate)
            CVBufferSetAttachment(pixelBuffer, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, .shouldPropagate)
        }
        
        let bufferSize = GLSize(self.size)
        var cachedTextureRef:CVOpenGLESTexture? = nil
        let _ = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.movieProcessingContext.coreVideoTextureCache, pixelBuffer, nil, GLenum(GL_TEXTURE_2D), GL_RGBA, bufferSize.width, bufferSize.height, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), 0, &cachedTextureRef)
        let cachedTexture = CVOpenGLESTextureGetName(cachedTextureRef!)
        
        renderFramebuffer = try Framebuffer(context:self.movieProcessingContext, orientation:.portrait, size:bufferSize, textureOnly:false, overriddenTexture:cachedTexture)
        
        renderFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(Color.black)
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
        renderQuadWithShader(colorSwizzlingShader, uniformSettings:ShaderUniformSettings(), vertexBufferObject:movieProcessingContext.standardImageVBO, inputTextures:[framebuffer.texturePropertiesForOutputRotation(.noRotation)], context: movieProcessingContext)
        
        if movieProcessingContext.supportsTextureCaches() {
            glFinish()
        } else {
            glReadPixels(0, 0, renderFramebuffer.size.width, renderFramebuffer.size.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), CVPixelBufferGetBaseAddress(pixelBuffer))
        }
    }
    
    // MARK: -
    // MARK: Audio support
    
    public func activateAudioTrack() {
        assetWriterAudioInput = AVAssetWriterInput(mediaType:AVMediaTypeAudio, outputSettings:self.audioSettings, sourceFormatHint:self.audioSourceFormatHint)

        assetWriter.add(assetWriterAudioInput!)
        assetWriterAudioInput?.expectsMediaDataInRealTime = encodingLiveVideo
    }
    
    public func processAudioBuffer(_ sampleBuffer:CMSampleBuffer, shouldInvalidateSampleWhenDone:Bool) {
        let work = {
            defer {
                if(shouldInvalidateSampleWhenDone) {
                    CMSampleBufferInvalidate(sampleBuffer)
                }
            }
            
            guard self.isRecording,
                self.assetWriter.status == .writing,
                !self.audioEncodingIsFinished,
                let assetWriterAudioInput = self.assetWriterAudioInput else {
                    self.synchronizedEncodingDebugPrint("Guard fell through, dropping audio sample")
                    return
            }
            
            let currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            
            guard (assetWriterAudioInput.isReadyForMoreMediaData || !self.encodingLiveVideo) else {
                print("Had to drop a audio sample at time \(currentSampleTime)")
                return
            }
            
            while(!assetWriterAudioInput.isReadyForMoreMediaData && !self.encodingLiveVideo && !self.audioEncodingIsFinished) {
                self.synchronizedEncodingDebugPrint("Audio waiting...")
                usleep(100000)
            }
            
            self.synchronizedEncodingDebugPrint("Process audio sample output")
            
            do {
                try NSObject.catchException {
                    if (!assetWriterAudioInput.append(sampleBuffer)) {
                        print("WARNING: Trouble appending audio sample buffer: \(String(describing: self.assetWriter.error))")
                    }
                }
            }
            catch {
                print("WARNING: Trouble appending audio sample buffer: \(error)")
            }
        }
        
        if(self.encodingLiveVideo) {
            movieProcessingContext.runOperationAsynchronously(work)
        }
        else {
            work()
        }
    }
    
    // Note: This is not used for synchronized encoding, only live video.
    public func readyForNextAudioBuffer() -> Bool {
        return true
    }
    
    func synchronizedEncodingDebugPrint(_ string: String) {
        if(synchronizedEncodingDebug && !encodingLiveVideo) { print(string) }
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
