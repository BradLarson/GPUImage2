public class Convolution3x3: TextureSamplingOperation {
    public var convolutionKernel:Matrix3x3 = Matrix3x3.centerOnly { didSet { uniformSettings["convolutionMatrix"] = convolutionKernel } }
    
    public init() {
        super.init(fragmentShader:Convolution3x3FragmentShader)
        
        ({convolutionKernel = Matrix3x3.centerOnly})()
    }
}
