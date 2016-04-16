public class SketchFilter: TextureSamplingOperation {
    public var edgeStrength:Float = 1.0 { didSet { uniformSettings["edgeStrength"] = edgeStrength } }
    
    public init() {
        super.init(fragmentShader:SketchFragmentShader)
        
        ({edgeStrength = 1.0})()
    }
}