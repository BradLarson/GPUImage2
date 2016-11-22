open class SwirlDistortion: BasicOperation {
    open var radius:Float = 0.5 { didSet { uniformSettings["radius"] = radius } }
    open var angle:Float = 1.0 { didSet { uniformSettings["angle"] = angle } }
    open var center:Position = Position.center { didSet { uniformSettings["center"] = center } }
    
    public init() {
        super.init(fragmentShader:SwirlFragmentShader, numberOfInputs:1)
        
        ({radius = 0.5})()
        ({angle = 1.0})()
        ({center = Position.center})()
    }
}
