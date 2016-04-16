public class AddBlend: BasicOperation {
    
    public init() {
        super.init(fragmentShader:AddBlendFragmentShader, numberOfInputs:2)
    }
}