public class ImageGenerator: ImageSource {
    public var size:Size

    public let targets = TargetContainer()
    var imageFramebuffer:Framebuffer!

    public init(size:Size) {
        self.size = size
        do {
            imageFramebuffer = try Framebuffer(context:sharedImageProcessingContext, orientation:.portrait, size:GLSize(size))
        } catch {
            fatalError("Could not construct framebuffer of size: \(size), error:\(error)")
        }
    }
    
    public func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        imageFramebuffer.lock()
        target.newFramebufferAvailable(imageFramebuffer, fromSourceIndex:atIndex)
    }
    
    func notifyTargets() {
        updateTargetsWithFramebuffer(imageFramebuffer)
    }
}
