import AVFoundation

public class MovieOutput: ImageConsumer {
    public let sources = SourceContainer()
    public let maximumInputs:UInt = 1

    let assetWriter:AVAssetWriter
    let assetWriterVideoInput:AVAssetWriterInput
    let assetWriterPixelBufferInput:AVAssetWriterInputPixelBufferAdaptor
    let size:Size
    let colorSwisslingShader:ShaderProgram
    
    public init(URL:NSURL, size:Size, fileType:String = AVFileTypeQuickTimeMovie, liveVideo:Bool = false, settings:[String:AnyObject]? = nil) throws {
        self.colorSwisslingShader = crashOnShaderCompileFailure("MovieOutput"){try sharedImageProcessingContext.programForVertexShader(defaultVertexShaderForInputs(1), fragmentShader:ColorSwizzlingFragmentShader)}

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
        
        // You need to use BGRA for the video in order to get realtime encoding. I use a color-swizzling shader to line up glReadPixels' normal RGBA output with the movie input's BGRA.
        let sourcePixelBufferAttributesDictionary:[String:AnyObject] = [kCVPixelBufferPixelFormatTypeKey as String:NSNumber(int:Int32(kCVPixelFormatType_32BGRA)),
                                                     kCVPixelBufferWidthKey as String:NSNumber(float:size.width),
                                                     kCVPixelBufferHeightKey as String:NSNumber(float:size.height)]

        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:assetWriterVideoInput, sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary)
        assetWriter.addInput(assetWriterVideoInput)
    }
    
    public func newFramebufferAvailable(framebuffer:Framebuffer, fromSourceIndex:UInt) {
    }
}


public extension Timestamp {
    public init(_ time:CMTime) {
        self.value = time.value
        self.timescale = time.timescale
        self.flags = TimestampFlags(rawValue:time.flags.rawValue)
        self.epoch = time.epoch
    }
}