open class Posterize: BasicOperation {
    open var colorLevels:Float = 10.0 { didSet { uniformSettings["colorLevels"] = colorLevels } }
    
    public init() {
        super.init(fragmentShader:PosterizeFragmentShader, numberOfInputs:1)
        
        ({colorLevels = 10.0})()
    }
}
