open class ThresholdSketchFilter: TextureSamplingOperation {
    open var edgeStrength:Float = 1.0 { didSet { uniformSettings["edgeStrength"] = edgeStrength } }
    open var threshold:Float = 0.25 { didSet { uniformSettings["threshold"] = threshold } }
    
    public init() {
        super.init(fragmentShader:ThresholdSketchFragmentShader)
        
        ({edgeStrength = 1.0})()
        ({threshold = 0.25})()
    }
}
