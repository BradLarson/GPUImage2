public class MonochromeFilter: BasicOperation {
    public var intensity:Float = 1.0 { didSet { uniformSettings["intensity"] = intensity } }
    public var color:Color = Color(red:0.6, green:0.45, blue:0.3, alpha:1.0) { didSet { uniformSettings["filterColor"] = color } }
    
    public init() {
        super.init(fragmentShader:MonochromeFragmentShader, numberOfInputs:1)
        
        ({intensity = 1.0})()
        ({color = Color(red:0.6, green:0.45, blue:0.3, alpha:1.0)})()
    }
}