open class OperationGroup: ImageProcessingOperation {
    let inputImageRelay = ImageRelay()
    let outputImageRelay = ImageRelay()
    
    open var sources:SourceContainer { get { return inputImageRelay.sources } }
    open var targets:TargetContainer { get { return outputImageRelay.targets } }
    open let maximumInputs:UInt = 1
    
    public init() {
    }
    
    open func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        inputImageRelay.newFramebufferAvailable(framebuffer, fromSourceIndex:fromSourceIndex)
    }

    open func configureGroup(_ configurationOperation:(_ input:ImageRelay, _ output:ImageRelay) -> ()) {
        configurationOperation(inputImageRelay, outputImageRelay)
    }
    
    open func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        outputImageRelay.transmitPreviousImage(to:target, atIndex:atIndex)
    }
}
