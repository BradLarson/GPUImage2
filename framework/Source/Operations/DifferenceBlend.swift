open class DifferenceBlend: BasicOperation {
    public init() {
        super.init(fragmentShader:DifferenceBlendFragmentShader, numberOfInputs:2)
    }
}
