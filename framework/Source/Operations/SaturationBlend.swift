public class SaturationBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:SaturationBlendFragmentShader, numberOfInputs:2)
    }
}