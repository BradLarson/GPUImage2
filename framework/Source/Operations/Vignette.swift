public class Vignette: BasicOperation {
    public var center:Position = Position.center { didSet { uniformSettings["vignetteCenter"] = center } }
    public var color:Color = Color.black { didSet { uniformSettings["vignetteColor"] = color } }
    public var start:Float = 0.3 { didSet { uniformSettings["vignetteStart"] = start } }
    public var end:Float = 0.75 { didSet { uniformSettings["vignetteEnd"] = end } }
    
    public init() {
        super.init(fragmentShader:VignetteFragmentShader, numberOfInputs:1)
        
        ({center = Position.center})()
        ({color = Color.black})()
        ({start = 0.3})()
        ({end = 0.75})()
    }
}
