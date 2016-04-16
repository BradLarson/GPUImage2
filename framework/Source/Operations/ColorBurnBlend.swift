public class ColorBurnBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:ColorBurnBlendFragmentShader, numberOfInputs:2)
    }
}