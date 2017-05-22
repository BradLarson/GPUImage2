open class TwoStageOperation: BasicOperation {
    public var overrideDownsamplingOptimization:Bool = false

//    override var outputFramebuffer:Framebuffer { get { return Framebuffer } }

    var downsamplingFactor:Float?

    override func internalRenderFunction(_ inputFramebuffer:Framebuffer, textureProperties:[InputTextureProperties]) {
        let outputRotation = overriddenOutputRotation ?? inputFramebuffer.orientation.rotationNeededForOrientation(.portrait)

        // Downsample
        let internalStageSize:GLSize
        let firstStageTextureProperties:[InputTextureProperties]
        let downsamplingFramebuffer:Framebuffer?
        if let downsamplingFactor = downsamplingFactor {
            internalStageSize = GLSize(Size(width:max(5.0, Float(renderFramebuffer.size.width) / downsamplingFactor), height:max(5.0, Float(renderFramebuffer.size.height) / downsamplingFactor)))
            downsamplingFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:internalStageSize, stencil:false)
            downsamplingFramebuffer!.lock()
            downsamplingFramebuffer!.activateFramebufferForRendering()
            clearFramebufferWithColor(backgroundColor)
            renderQuadWithShader(sharedImageProcessingContext.passthroughShader, uniformSettings:nil, vertexBufferObject:sharedImageProcessingContext.standardImageVBO, inputTextures:textureProperties)
            releaseIncomingFramebuffers()

            firstStageTextureProperties = [downsamplingFramebuffer!.texturePropertiesForOutputRotation(.noRotation)]
        } else {
            firstStageTextureProperties = textureProperties
            internalStageSize = renderFramebuffer.size
            downsamplingFramebuffer = nil
        }

        // Render first stage
        let firstStageFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:internalStageSize, stencil:false)
        firstStageFramebuffer.lock()

        firstStageFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(backgroundColor)
        
        let texelSize = inputFramebuffer.initialStageTexelSize(for:outputRotation)
        uniformSettings["texelWidth"] = texelSize.width * (downsamplingFactor ?? 1.0)
        uniformSettings["texelHeight"] = texelSize.height * (downsamplingFactor ?? 1.0)
        
        renderQuadWithShader(shader, uniformSettings:uniformSettings, vertexBufferObject:sharedImageProcessingContext.standardImageVBO, inputTextures:firstStageTextureProperties)
        if let downsamplingFramebuffer = downsamplingFramebuffer {
            downsamplingFramebuffer.unlock()
        } else {
            releaseIncomingFramebuffers()
        }
        
        let secondStageTexelSize = renderFramebuffer.texelSize(for:.noRotation)
        uniformSettings["texelWidth"] = secondStageTexelSize.width * (downsamplingFactor ?? 1.0)
        uniformSettings["texelHeight"] = 0.0
        
        // Render second stage and upsample
        if (downsamplingFactor != nil) {
            let beforeUpsamplingFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:internalStageSize, stencil:false)
            beforeUpsamplingFramebuffer.activateFramebufferForRendering()
            beforeUpsamplingFramebuffer.lock()
            clearFramebufferWithColor(backgroundColor)
            renderQuadWithShader(shader, uniformSettings:uniformSettings, vertexBufferObject:sharedImageProcessingContext.standardImageVBO, inputTextures:[firstStageFramebuffer.texturePropertiesForOutputRotation(.noRotation)])
            firstStageFramebuffer.unlock()
            
            renderFramebuffer.activateFramebufferForRendering()
            renderQuadWithShader(sharedImageProcessingContext.passthroughShader, uniformSettings:nil, vertexBufferObject:sharedImageProcessingContext.standardImageVBO, inputTextures:[beforeUpsamplingFramebuffer.texturePropertiesForOutputRotation(.noRotation)])
            beforeUpsamplingFramebuffer.unlock()
        } else {
            renderFramebuffer.activateFramebufferForRendering()
            renderQuadWithShader(shader, uniformSettings:uniformSettings, vertexBufferObject:sharedImageProcessingContext.standardImageVBO, inputTextures:[firstStageFramebuffer.texturePropertiesForOutputRotation(.noRotation)])
            firstStageFramebuffer.unlock()
        }
    }
}
