open class PrewittEdgeDetection: TextureSamplingOperation {
    open var edgeStrength:Float = 1.0 { didSet { uniformSettings["edgeStrength"] = edgeStrength } }
    
    public init() {
        super.init(fragmentShader:PrewittEdgeDetectionFragmentShader)
        
        ({edgeStrength = 1.0})()
    }
}
