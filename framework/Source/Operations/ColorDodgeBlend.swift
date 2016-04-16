public class ColorDodgeBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:ColorDodgeBlendFragmentShader, numberOfInputs:2)
    }
}