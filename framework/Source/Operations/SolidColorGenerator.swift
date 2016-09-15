open class SolidColorGenerator: ImageGenerator {

    open func renderColor(_ color:Color) {
        imageFramebuffer.activateFramebufferForRendering()
        
        clearFramebufferWithColor(color)
        
        notifyTargets()
    }
}
