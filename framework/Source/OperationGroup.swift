public class OperationGroup: ImageProcessingOperation {
    let inputImageRelay = ImageRelay()
    let outputImageRelay = ImageRelay()
    
    public var sources:SourceContainer { get { return inputImageRelay.sources } }
    public var targets:TargetContainer { get { return outputImageRelay.targets } }
    public let maximumInputs:UInt = 1
    
    public init() {
    }
    
    public func newFramebufferAvailable(framebuffer:Framebuffer, fromSourceIndex:UInt) {
        inputImageRelay.newFramebufferAvailable(framebuffer, fromSourceIndex:fromSourceIndex)
    }

    public func configureGroup(configurationOperation:(input:ImageRelay, output:ImageRelay) -> ()) {
        configurationOperation(input:inputImageRelay, output:outputImageRelay)
    }
    
    public func transmitPreviousImageToTarget(target:ImageConsumer, atIndex:UInt) {
        outputImageRelay.transmitPreviousImageToTarget(target, atIndex:atIndex)
    }
}