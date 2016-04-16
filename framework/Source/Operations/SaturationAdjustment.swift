public class SaturationAdjustment: BasicOperation {
    public var saturation:Float = 1.0 { didSet { uniformSettings["saturation"] = saturation } }
    
    public init() {
        super.init(fragmentShader:SaturationFragmentShader, numberOfInputs:1)

        ({saturation = 1.0})()
    }
}