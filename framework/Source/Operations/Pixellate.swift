public class Pixellate: BasicOperation {
    public var fractionalWidthOfAPixel:Float = 0.01 {
        didSet {
            let imageWidth = 1.0 / Float(self.renderFramebuffer?.size.width ?? 2048)
            uniformSettings["fractionalWidthOfPixel"] = max(fractionalWidthOfAPixel, imageWidth)
        }
    }
    
    public init() {
        super.init(fragmentShader:PixellateFragmentShader, numberOfInputs:1)
        
        ({fractionalWidthOfAPixel = 0.01})()
    }
}