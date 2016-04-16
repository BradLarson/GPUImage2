public class PolkaDot: BasicOperation {
    public var dotScaling:Float = 0.90 { didSet { uniformSettings["dotScaling"] = dotScaling } }
    public var fractionalWidthOfAPixel:Float = 0.01 {
        didSet {
            let imageWidth = 1.0 / Float(self.renderFramebuffer?.size.width ?? 2048)
            uniformSettings["fractionalWidthOfPixel"] = max(fractionalWidthOfAPixel, imageWidth)
        }
    }
    
    public init() {
        super.init(fragmentShader:PolkaDotFragmentShader, numberOfInputs:1)
        
        ({fractionalWidthOfAPixel = 0.01})()
        ({dotScaling = 0.90})()
    }
}