open class HighlightAndShadowTint: BasicOperation {
    open var shadowTintIntensity:Float = 0.0 { didSet { uniformSettings["shadowTintIntensity"] = shadowTintIntensity } }
    open var highlightTintIntensity:Float = 0.0 { didSet { uniformSettings["highlightTintIntensity"] = highlightTintIntensity } }
    open var shadowTintColor:Color = Color.red { didSet { uniformSettings["shadowTintColor"] = shadowTintColor } }
    open var highlightTintColor:Color = Color.blue { didSet { uniformSettings["highlightTintColor"] = highlightTintColor } }
    
    public init() {
        super.init(fragmentShader:HighlightShadowTintFragmentShader, numberOfInputs:1)
        
        ({shadowTintIntensity = 0.0})()
        ({highlightTintIntensity = 0.0})()
        ({shadowTintColor = Color.red})()
        ({highlightTintColor = Color.blue})()
    }
}
