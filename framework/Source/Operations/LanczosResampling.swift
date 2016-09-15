open class LanczosResampling: BasicOperation {
    public init() {
        super.init(vertexShader:LanczosResamplingVertexShader, fragmentShader:LanczosResamplingFragmentShader)
    }

    override func internalRenderFunction(_ inputFramebuffer:Framebuffer, textureProperties:[InputTextureProperties]) {
        let outputRotation = overriddenOutputRotation ?? inputFramebuffer.orientation.rotationNeededForOrientation(.portrait)
        
        // Shrink the vertical component of the first stage
        let inputSize = inputFramebuffer.sizeForTargetOrientation(.portrait)
        let firstStageFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(.portrait, size:GLSize(width:inputSize.width, height:renderFramebuffer.size.height), stencil:false)
        firstStageFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(backgroundColor)
        
        let texelSize = inputFramebuffer.initialStageTexelSize(for:outputRotation)
        uniformSettings["texelWidth"] = texelSize.width
        uniformSettings["texelHeight"] = texelSize.height
        
        renderQuadWithShader(shader, uniformSettings:uniformSettings, vertices:standardImageVertices, inputTextures:textureProperties)
        releaseIncomingFramebuffers()

        // Shrink the width component of the result
        let secondStageTexelSize = firstStageFramebuffer.texelSize(for:.noRotation)
        uniformSettings["texelWidth"] = secondStageTexelSize.width
        uniformSettings["texelHeight"] = 0.0
        
        renderFramebuffer.activateFramebufferForRendering()
        renderQuadWithShader(shader, uniformSettings:uniformSettings, vertices:standardImageVertices, inputTextures:[firstStageFramebuffer.texturePropertiesForOutputRotation(.noRotation)])
        firstStageFramebuffer.unlock()
    }
}
