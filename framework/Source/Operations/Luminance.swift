public class Luminance: BasicOperation {
    public init() {
        super.init(fragmentShader:LuminanceFragmentShader, numberOfInputs:1)
    }
}