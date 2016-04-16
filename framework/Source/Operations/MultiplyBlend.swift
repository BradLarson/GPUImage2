public class MultiplyBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:MultiplyBlendFragmentShader, numberOfInputs:2)
    }
}