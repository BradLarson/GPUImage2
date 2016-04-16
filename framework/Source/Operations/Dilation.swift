public class Dilation: TwoStageOperation {
    public var radius:UInt {
        didSet {
            switch radius {
            case 0, 1:
                shader = crashOnShaderCompileFailure("Dilation"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation1VertexShader, fragmentShader:Dilation1FragmentShader)}
            case 2:
                shader = crashOnShaderCompileFailure("Dilation"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation2VertexShader, fragmentShader:Dilation2FragmentShader)}
            case 3:
                shader = crashOnShaderCompileFailure("Dilation"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation3VertexShader, fragmentShader:Dilation3FragmentShader)}
            case 4:
                shader = crashOnShaderCompileFailure("Dilation"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation4VertexShader, fragmentShader:Dilation4FragmentShader)}
            default:
                shader = crashOnShaderCompileFailure("Dilation"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation4VertexShader, fragmentShader:Dilation4FragmentShader)}
            }
        }
    }
    
    public init() {
        radius = 1
        let initialShader = crashOnShaderCompileFailure("Dilation"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation1VertexShader, fragmentShader:Dilation1FragmentShader)}
        super.init(shader:initialShader, numberOfInputs:1)
    }
}