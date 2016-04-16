public class LinearBurnBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:LinearBurnBlendFragmentShader, numberOfInputs:2)
    }
}