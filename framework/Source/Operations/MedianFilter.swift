public class MedianFilter: TextureSamplingOperation {
    public init() {
        super.init(fragmentShader:MedianFragmentShader)
    }
}