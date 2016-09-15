open class PinchDistortion: BasicOperation {
    open var radius:Float = 1.0 { didSet { uniformSettings["radius"] = radius } }
    open var scale:Float = 0.5 { didSet { uniformSettings["scale"] = scale } }
    open var center:Position = Position.center { didSet { uniformSettings["center"] = center } }
    
    public init() {
        super.init(fragmentShader:PinchDistortionFragmentShader, numberOfInputs:1)
        
        ({radius = 1.0})()
        ({scale = 0.5})()
        ({center = Position.center})()
    }
}
