public class OpacityAdjustment: BasicOperation {
    public var opacity:Float = 0.0 { didSet { uniformSettings["opacity"] = opacity } }
    
    public init() {
        super.init(fragmentShader:OpacityFragmentShader, numberOfInputs:1)
        
        ({opacity = 0.0})()
    }
}