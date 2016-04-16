public class WhiteBalance: BasicOperation {
    public var temperature:Float = 5000.0 { didSet { uniformSettings["temperature"] = temperature < 5000.0 ? 0.0004 * (temperature - 5000.0) : 0.00006 * (temperature - 5000.0) } }
    public var tint:Float = 0.0 { didSet { uniformSettings["tint"] = tint / 100.0 } }
    
    public init() {
        super.init(fragmentShader:WhiteBalanceFragmentShader, numberOfInputs:1)
        
        ({temperature = 5000.0})()
        ({tint = 0.0})()
    }
}