open class HueAdjustment: BasicOperation {
    open var hue:Float = 90.0 { didSet { uniformSettings["hueAdjust"] = hue } }
    
    public init() {
        super.init(fragmentShader:HueFragmentShader, numberOfInputs:1)
        
        ({hue = 90.0})()
    }
}
