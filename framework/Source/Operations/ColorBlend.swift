public class ColorBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:ColorBlendFragmentShader, numberOfInputs:2)
    }
}