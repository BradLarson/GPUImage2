public class Haze: BasicOperation {
    public var distance:Float = 0.2 { didSet { uniformSettings["hazeDistance"] = distance } }
    public var slope:Float = 0.0 { didSet { uniformSettings["slope"] = slope } }
    
    public init() {
        super.init(fragmentShader:HazeFragmentShader, numberOfInputs:1)
        
        ({distance = 0.2})()
        ({slope = 0.0})()
    }
}