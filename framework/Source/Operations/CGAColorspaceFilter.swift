public class CGAColorspaceFilter: BasicOperation {
    public init() {
        super.init(fragmentShader:CGAColorspaceFragmentShader, numberOfInputs:1)
    }
}