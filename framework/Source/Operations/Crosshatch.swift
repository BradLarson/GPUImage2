open class Crosshatch: BasicOperation {
    open var crossHatchSpacing:Float = 0.03 { didSet { uniformSettings["crossHatchSpacing"] = crossHatchSpacing } }
    open var lineWidth:Float = 0.003 { didSet { uniformSettings["lineWidth"] = lineWidth } }
    
    public init() {
        super.init(fragmentShader:CrosshatchFragmentShader, numberOfInputs:1)
        
        ({crossHatchSpacing = 0.03})()
        ({lineWidth = 0.003})()
    }
}
