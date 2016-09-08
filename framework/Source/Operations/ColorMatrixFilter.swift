public class ColorMatrixFilter: BasicOperation {
    public var intensity:Float = 1.0 { didSet { uniformSettings["intensity"] = intensity } }
    public var colorMatrix:Matrix4x4 = Matrix4x4.identity { didSet { uniformSettings["colorMatrix"] = colorMatrix } }
    
    public init() {
        
        super.init(fragmentShader:ColorMatrixFragmentShader, numberOfInputs:1)
        
        ({intensity = 1.0})()
        ({colorMatrix = Matrix4x4.identity})()
    }
}
