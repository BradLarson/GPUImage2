open class OperationGroup: ImageProcessingOperation {
    let inputImageRelay = ImageRelay()
    let outputImageRelay = ImageRelay()
    
    public var sources:SourceContainer { get { return inputImageRelay.sources } }
    public var targets:TargetContainer { get { return outputImageRelay.targets } }
    public let maximumInputs:UInt = 1
    
    public init() {
    }
    
    public func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        inputImageRelay.newFramebufferAvailable(framebuffer, fromSourceIndex:fromSourceIndex)
    }

    public func configureGroup(_ configurationOperation:(_ input:ImageRelay, _ output:ImageRelay) -> ()) {
        configurationOperation(inputImageRelay, outputImageRelay)
    }
    
    public func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        outputImageRelay.transmitPreviousImage(to:target, atIndex:atIndex)
    }
}
