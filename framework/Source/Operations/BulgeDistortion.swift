open class BulgeDistortion: BasicOperation {
    open var radius:Float = 0.25 { didSet { uniformSettings["radius"] = radius } }
    open var scale:Float = 0.5 { didSet { uniformSettings["scale"] = scale } }
    open var center:Position = Position.center { didSet { uniformSettings["center"] = center } }
    
    public init() {
        super.init(fragmentShader:BulgeDistortionFragmentShader, numberOfInputs:1)
        
        ({radius = 0.25})()
        ({scale = 0.5})()
        ({center = Position.center})()
    }
}
