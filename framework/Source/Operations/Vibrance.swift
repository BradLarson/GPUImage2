open class Vibrance: BasicOperation {
    open var vibrance:Float = 0.0 { didSet { uniformSettings["vibrance"] = vibrance } }
    
    public init() {
        super.init(fragmentShader:VibranceFragmentShader, numberOfInputs:1)
        
        ({vibrance = 0.0})()
    }
}
