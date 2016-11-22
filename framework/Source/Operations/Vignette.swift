open class Vignette: BasicOperation {
    open var center:Position = Position.center { didSet { uniformSettings["vignetteCenter"] = center } }
    open var color:Color = Color.black { didSet { uniformSettings["vignetteColor"] = color } }
    open var start:Float = 0.3 { didSet { uniformSettings["vignetteStart"] = start } }
    open var end:Float = 0.75 { didSet { uniformSettings["vignetteEnd"] = end } }
    
    public init() {
        super.init(fragmentShader:VignetteFragmentShader, numberOfInputs:1)
        
        ({center = Position.center})()
        ({color = Color.black})()
        ({start = 0.3})()
        ({end = 0.75})()
    }
}
