public class OverlayBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:OverlayBlendFragmentShader, numberOfInputs:2)
    }
}