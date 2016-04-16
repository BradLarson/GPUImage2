public class LuminosityBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:LuminosityBlendFragmentShader, numberOfInputs:2)
    }
}