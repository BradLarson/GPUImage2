public class HighlightsAndShadows: BasicOperation {
    public var shadows:Float = 0.0 { didSet { uniformSettings["shadows"] = shadows } }
    public var highlights:Float = 1.0 { didSet { uniformSettings["highlights"] = highlights } }
    
    public init() {
        super.init(fragmentShader:HighlightShadowFragmentShader, numberOfInputs:1)
        
        ({shadows = 0.0})()
        ({highlights = 1.0})()
    }
}