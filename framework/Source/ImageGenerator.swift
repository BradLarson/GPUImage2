open class ImageGenerator: ImageSource {
    open var size:Size

    open let targets = TargetContainer()
    var imageFramebuffer:Framebuffer!

    public init(size:Size) {
        self.size = size
        do {
            imageFramebuffer = try Framebuffer(context:sharedImageProcessingContext, orientation:.portrait, size:GLSize(size))
        } catch {
            fatalError("Could not construct framebuffer of size: \(size), error:\(error)")
        }
    }
    
    open func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        imageFramebuffer.lock()
        target.newFramebufferAvailable(imageFramebuffer, fromSourceIndex:atIndex)
    }
    
    func notifyTargets() {
        updateTargetsWithFramebuffer(imageFramebuffer)
    }
}
