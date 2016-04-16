public class Erosion: TwoStageOperation {
    public var radius:UInt {
        didSet {
            switch radius {
                case 0, 1:
                    shader = crashOnShaderCompileFailure("Erosion"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation1VertexShader, fragmentShader:Erosion1FragmentShader)}
                case 2:
                    shader = crashOnShaderCompileFailure("Erosion"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation2VertexShader, fragmentShader:Erosion2FragmentShader)}
                case 3:
                    shader = crashOnShaderCompileFailure("Erosion"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation3VertexShader, fragmentShader:Erosion3FragmentShader)}
                case 4:
                    shader = crashOnShaderCompileFailure("Erosion"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation4VertexShader, fragmentShader:Erosion4FragmentShader)}
                default:
                    shader = crashOnShaderCompileFailure("Erosion"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation4VertexShader, fragmentShader:Erosion4FragmentShader)}
            }
        }
    }
    
    public init() {
        radius = 1
        let initialShader = crashOnShaderCompileFailure("Erosion"){try sharedImageProcessingContext.programForVertexShader(ErosionDilation1VertexShader, fragmentShader:Erosion1FragmentShader)}
        super.init(shader:initialShader, numberOfInputs:1)
    }
}