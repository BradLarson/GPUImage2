public class Halftone: BasicOperation {
    public var fractionalWidthOfAPixel:Float = 0.01 {
        didSet {
            sharedImageProcessingContext.runOperationAsynchronously{
                let imageWidth = 1.0 / Float(self.renderFramebuffer?.size.width ?? 2048)
                self.uniformSettings["fractionalWidthOfPixel"] = max(self.fractionalWidthOfAPixel, imageWidth)
            }
        }
    }
    
    public init() {
        super.init(fragmentShader:HalftoneFragmentShader, numberOfInputs:1)
        
        ({fractionalWidthOfAPixel = 0.01})()
    }
}
