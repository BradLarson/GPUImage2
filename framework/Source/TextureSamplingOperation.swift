public class TextureSamplingOperation: BasicOperation {
    public var overriddenTexelSize:Size?
    
    public init(vertexShader:String = NearbyTexelSamplingVertexShader, fragmentShader:String, numberOfInputs:UInt = 1) {
        super.init(vertexShader:vertexShader, fragmentShader:fragmentShader, numberOfInputs:numberOfInputs)
    }
    
    override func configureFramebufferSpecificUniforms(inputFramebuffer:Framebuffer) {
        let outputRotation = overriddenOutputRotation ?? inputFramebuffer.orientation.rotationNeededForOrientation(.Portrait)
        let texelSize = overriddenTexelSize ?? inputFramebuffer.texelSizeForRotation(outputRotation)
        uniformSettings["texelWidth"] = texelSize.width
        uniformSettings["texelHeight"] = texelSize.height
    }
}