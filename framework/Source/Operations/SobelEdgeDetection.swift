open class SobelEdgeDetection: TextureSamplingOperation {
    open var edgeStrength:Float = 1.0 { didSet { uniformSettings["edgeStrength"] = edgeStrength } }
    
    public init() {
        super.init(fragmentShader:SobelEdgeDetectionFragmentShader)
        
        ({edgeStrength = 1.0})()
    }
}
