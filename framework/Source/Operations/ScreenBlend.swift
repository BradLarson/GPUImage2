public class ScreenBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:ScreenBlendFragmentShader, numberOfInputs:2)
    }
}