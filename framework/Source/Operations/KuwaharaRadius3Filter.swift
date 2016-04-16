public class KuwaharaRadius3Filter: BasicOperation {
    public init() {
        super.init(fragmentShader:KuwaharaRadius3FragmentShader, numberOfInputs:1)
    }
}