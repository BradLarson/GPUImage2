public class StretchDistortion: BasicOperation {
    public var center:Position = Position.center { didSet { uniformSettings["center"] = center } }
    
    public init() {
        super.init(fragmentShader:StretchDistortionFragmentShader, numberOfInputs:1)
        
        ({center = Position.center})()
    }
}
