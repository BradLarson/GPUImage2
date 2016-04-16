public class ExclusionBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:ExclusionBlendFragmentShader, numberOfInputs:2)
    }
}