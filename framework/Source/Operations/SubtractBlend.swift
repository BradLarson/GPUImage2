public class SubtractBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:SubtractBlendFragmentShader, numberOfInputs:2)
    }
}