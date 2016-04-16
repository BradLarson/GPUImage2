public class EmbossFilter : Convolution3x3 {
    public var intensity:Float = 1.0 {
        didSet {
            self.convolutionKernel = Matrix3x3(rowMajorValues:[
                intensity * (-2.0), -intensity, 0.0,
                -intensity, 1.0, intensity,
                0.0, intensity, intensity * 2.0])
        }
    }
    
    public override init() {
        super.init()
        
        ({intensity = 1.0})()
    }
}