public class SoftLightBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:SoftLightBlendFragmentShader, numberOfInputs:2)
    }
}