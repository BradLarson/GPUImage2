public class HistogramDisplay: BasicOperation {
    public init() {
        super.init(vertexShader:HistogramDisplayVertexShader, fragmentShader:HistogramDisplayFragmentShader, numberOfInputs:1)
    }
}