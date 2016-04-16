public class LanczosResampling: BasicOperation {
    public init() {
        super.init(vertexShader:LanczosResamplingVertexShader, fragmentShader:LanczosResamplingFragmentShader)
    }

    override func internalRenderFunction(inputFramebuffer:Framebuffer, textureProperties:[InputTextureProperties]) {
        let outputRotation = overriddenOutputRotation ?? inputFramebuffer.orientation.rotationNeededForOrientation(.Portrait)
        
        // Shrink the vertical component of the first stage
        let inputSize = inputFramebuffer.sizeForTargetOrientation(.Portrait)
        let firstStageFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.Portrait, size:GLSize(width:inputSize.width, height:renderFramebuffer.size.height), stencil:false)
        firstStageFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(backgroundColor)
        
        let texelSize = inputFramebuffer.initialStageTexelSizeForRotation(outputRotation)
        uniformSettings["texelWidth"] = texelSize.width
        uniformSettings["texelHeight"] = texelSize.height
        
        renderQuadWithShader(shader, uniformSettings:uniformSettings, vertices:standardImageVertices, inputTextures:textureProperties)
        releaseIncomingFramebuffers()

        // Shrink the width component of the result
        let secondStageTexelSize = firstStageFramebuffer.texelSizeForRotation(.NoRotation)
        uniformSettings["texelWidth"] = secondStageTexelSize.width
        uniformSettings["texelHeight"] = 0.0
        
        renderFramebuffer.activateFramebufferForRendering()
        renderQuadWithShader(shader, uniformSettings:uniformSettings, vertices:standardImageVertices, inputTextures:[firstStageFramebuffer.texturePropertiesForOutputRotation(.NoRotation)])
        firstStageFramebuffer.unlock()
    }
}