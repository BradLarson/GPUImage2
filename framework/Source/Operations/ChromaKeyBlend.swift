open class ChromaKeyBlend: BasicOperation {
    open var thresholdSensitivity:Float = 0.4 { didSet { uniformSettings["thresholdSensitivity"] = thresholdSensitivity } }
    open var smoothing:Float = 0.1 { didSet { uniformSettings["smoothing"] = smoothing } }
    open var colorToReplace:Color = Color.green { didSet { uniformSettings["colorToReplace"] = colorToReplace } }
    
    public init() {
        super.init(fragmentShader:ChromaKeyBlendFragmentShader, numberOfInputs:2)
        
        ({thresholdSensitivity = 0.4})()
        ({smoothing = 0.1})()
        ({colorToReplace = Color.green})()
    }
}
