public class SolidColorGenerator: ImageGenerator {

    public func renderColor(color:Color) {
        imageFramebuffer.activateFramebufferForRendering()
        
        clearFramebufferWithColor(color)
        
        notifyTargets()
    }
}