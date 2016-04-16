public class HardLightBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:HardLightBlendFragmentShader, numberOfInputs:2)
    }
}