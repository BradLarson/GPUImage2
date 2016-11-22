open class ImageBuffer: ImageProcessingOperation {
    // TODO: Dynamically release framebuffers on buffer resize
    open var bufferSize:UInt = 1
    open var activatePassthroughOnNextFrame = true
    
    open let maximumInputs:UInt = 1
    open let targets = TargetContainer()
    open let sources = SourceContainer()
    var bufferedFramebuffers = [Framebuffer]()

    open func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        bufferedFramebuffers.append(framebuffer)
        if (bufferedFramebuffers.count > Int(bufferSize)) {
            let releasedFramebuffer = bufferedFramebuffers.removeFirst()
            updateTargetsWithFramebuffer(releasedFramebuffer)
            releasedFramebuffer.unlock()
        } else if activatePassthroughOnNextFrame {
            activatePassthroughOnNextFrame = false
            // Pass along the current frame to keep processing going until the buffer is built up
            framebuffer.lock()
            updateTargetsWithFramebuffer(framebuffer)
            framebuffer.unlock()
        }
    }
    
    open func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
        // Buffers most likely won't need this
    }
}
