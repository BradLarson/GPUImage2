public class GammaAdjustment: BasicOperation {
    public var gamma:Float = 1.0 { didSet { uniformSettings["gamma"] = gamma } }
    
    public init() {
        super.init(fragmentShader:GammaFragmentShader, numberOfInputs:1)
        
        ({gamma = 1.0})()
    }
}