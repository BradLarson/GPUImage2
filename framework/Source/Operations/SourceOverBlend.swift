public class SourceOverBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:SourceOverBlendFragmentShader, numberOfInputs:2)
    }
}