public class TextureSamplingOperation: BasicOperation {
    public var overriddenTexelSize:Size?
    
    public init(vertexShader:String = NearbyTexelSamplingVertexShader, fragmentShader:String) {
        super.init(vertexShader:vertexShader, fragmentShader:fragmentShader, numberOfInputs:1)
    }
    
    override func configureFramebufferSpecificUniforms(inputFramebuffer:Framebuffer) {
        let outputRotation = overriddenOutputRotation ?? inputFramebuffer.orientation.rotationNeededForOrientation(.Portrait)
        let texelSize = overriddenTexelSize ?? inputFramebuffer.texelSizeForRotation(outputRotation)
        uniformSettings["texelWidth"] = texelSize.width
        uniformSettings["texelHeight"] = texelSize.height
    }
}