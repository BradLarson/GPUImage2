public class ChromaKeying: BasicOperation {
    public var thresholdSensitivity:Float = 0.4 { didSet { uniformSettings["thresholdSensitivity"] = thresholdSensitivity } }
    public var smoothing:Float = 0.1 { didSet { uniformSettings["smoothing"] = smoothing } }
    public var colorToReplace:Color = Color.green { didSet { uniformSettings["colorToReplace"] = colorToReplace } }
    
    public init() {
        super.init(fragmentShader:ChromaKeyFragmentShader, numberOfInputs:1)
        
        ({thresholdSensitivity = 0.4})()
        ({smoothing = 0.1})()
        ({colorToReplace = Color.green})()
    }
}
