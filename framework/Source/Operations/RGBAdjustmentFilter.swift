open class RGBAdjustment: BasicOperation {
    open var red:Float = 1.0 { didSet { uniformSettings["redAdjustment"] = red } }
    open var blue:Float = 1.0 { didSet { uniformSettings["blueAdjustment"] = blue } }
    open var green:Float = 1.0 { didSet { uniformSettings["greenAdjustment"] = green } }
    
    public init() {
        super.init(fragmentShader:RGBAdjustmentFragmentShader, numberOfInputs:1)
        
        ({red = 1.0})()
        ({blue = 1.0})()
        ({green = 1.0})()
    }
}
