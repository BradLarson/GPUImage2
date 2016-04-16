public class DarkenBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:DarkenBlendFragmentShader, numberOfInputs:2)
    }
}