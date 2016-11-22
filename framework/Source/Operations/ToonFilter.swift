open class ToonFilter: TextureSamplingOperation {
    open var threshold:Float = 0.2 { didSet { uniformSettings["threshold"] = threshold } }
    open var quantizationLevels:Float = 10.0 { didSet { uniformSettings["quantizationLevels"] = quantizationLevels } }
    
    public init() {
        super.init(fragmentShader:ToonFragmentShader)
        
        ({threshold = 0.2})()
        ({quantizationLevels = 10.0})()
    }
}
