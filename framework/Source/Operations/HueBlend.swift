public class HueBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:HueBlendFragmentShader, numberOfInputs:2)
    }
}