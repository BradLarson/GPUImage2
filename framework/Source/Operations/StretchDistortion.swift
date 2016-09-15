open class StretchDistortion: BasicOperation {
    open var center:Position = Position.center { didSet { uniformSettings["center"] = center } }
    
    public init() {
        super.init(fragmentShader:StretchDistortionFragmentShader, numberOfInputs:1)
        
        ({center = Position.center})()
    }
}
