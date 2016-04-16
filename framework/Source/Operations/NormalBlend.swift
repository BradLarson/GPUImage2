public class NormalBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:NormalBlendFragmentShader, numberOfInputs:2)
    }
}