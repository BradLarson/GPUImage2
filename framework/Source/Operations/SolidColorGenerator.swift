public class SolidColorGenerator: ImageGenerator {

    public func renderColor(_ color:Color) {
        imageFramebuffer.activateFramebufferForRendering()
        
        clearFramebufferWithColor(color)
        
        notifyTargets()
    }
}
