public class LightenBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:LightenBlendFragmentShader, numberOfInputs:2)
    }
}