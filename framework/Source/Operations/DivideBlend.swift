public class DivideBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:DivideBlendFragmentShader, numberOfInputs:2)
    }
}