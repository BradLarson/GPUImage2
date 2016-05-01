import AVFoundation

public class MovieInput: ImageSource {
    public let targets = TargetContainer()
    
    let yuvConversionShader:ShaderProgram
    let asset:AVAsset
    let assetReader:AVAssetReader
    let playAtActualSpeed:Bool
    let loop:Bool

    // TODO: Add movie reader synchronization
    // TODO: Someone will have to add back in the AVPlayerItem logic, because I don't know how that works
    public init(asset:AVAsset, playAtActualSpeed:Bool = false, loop:Bool = false) throws {
        self.asset = asset
        self.playAtActualSpeed = playAtActualSpeed
        self.loop = loop
        self.yuvConversionShader = crashOnShaderCompileFailure("MovieInput"){try sharedImageProcessingContext.programForVertexShader(defaultVertexShaderForInputs(2), fragmentShader:YUVConversionFullRangeFragmentShader)}
        
        assetReader = try AVAssetReader(asset:self.asset)
        
        let outputSettings:[String:AnyObject] = [(kCVPixelBufferPixelFormatTypeKey as String):NSNumber(int:Int32(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange))]
        let readerVideoTrackOutput = AVAssetReaderTrackOutput(track:self.asset.tracksWithMediaType(AVMediaTypeVideo)[0], outputSettings:outputSettings)
        readerVideoTrackOutput.alwaysCopiesSampleData = false
        assetReader.addOutput(readerVideoTrackOutput)
        // TODO: Audio here
    }

    public convenience init(url:NSURL, playAtActualSpeed:Bool = false, loop:Bool = false) throws {
        let inputOptions = [AVURLAssetPreferPreciseDurationAndTimingKey:NSNumber(bool:true)]
        let inputAsset = AVURLAsset(URL:url, options:inputOptions)
        try self.init(asset:inputAsset, playAtActualSpeed:playAtActualSpeed, loop:loop)
    }

    // MARK: -
    // MARK: Playback control

    public func start() {
        guard assetReader.startReading() else {
            print("Couldn't start reading")
            return
        }
        
        var readerVideoTrackOutput:AVAssetReaderOutput? = nil;
        
        for output in assetReader.outputs {
            if(output.mediaType == AVMediaTypeVideo) {
                readerVideoTrackOutput = output;
            }
        }
        
        while (assetReader.status == .Reading) {
            readNextVideoFrameFromOutput(readerVideoTrackOutput!)
        }
        
        if (assetReader.status == .Completed) {
            assetReader.cancelReading()
            
            if (loop) {
                // TODO: Restart movie processing
            } else {
                endProcessing()
            }
            
        }

    }
    
    public func cancel() {
        assetReader.cancelReading()
        self.endProcessing()
    }
    
    func endProcessing() {
        
    }
    
    // MARK: -
    // MARK: Internal processing functions
    
    func readNextVideoFrameFromOutput(videoTrackOutput:AVAssetReaderOutput) {
        
    }

    public func transmitPreviousImageToTarget(target:ImageConsumer, atIndex:UInt) {
        // Not needed for movie inputs
    }
}