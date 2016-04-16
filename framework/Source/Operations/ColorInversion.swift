public class ColorInversion: BasicOperation {
    public init() {
        super.init(fragmentShader:ColorInvertFragmentShader, numberOfInputs:1)
    }
}