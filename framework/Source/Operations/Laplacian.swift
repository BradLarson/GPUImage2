public class Laplacian: TextureSamplingOperation {
    public init() {
        super.init(fragmentShader:LaplacianFragmentShader)
    }
}