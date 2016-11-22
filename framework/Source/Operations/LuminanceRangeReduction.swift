open class LuminanceRangeReduction: BasicOperation {
    open var rangeReductionFactor:Float = 0.6 { didSet { uniformSettings["rangeReduction"] = rangeReductionFactor } }
    
    public init() {
        super.init(fragmentShader:LuminanceRangeFragmentShader, numberOfInputs:1)
        
        ({rangeReductionFactor = 0.6})()
    }
}
