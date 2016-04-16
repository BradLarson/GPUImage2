// TODO: auto-generate shaders for this, per the Gaussian blur method

public class BilateralBlur: TwoStageOperation {
    public var distanceNormalizationFactor:Float = 8.0 { didSet { uniformSettings["distanceNormalizationFactor"] = distanceNormalizationFactor } }
    
    public init() {
        super.init(vertexShader:BilateralBlurVertexShader, fragmentShader:BilateralBlurFragmentShader)
        
        ({distanceNormalizationFactor = 1.0})()
    }
}
