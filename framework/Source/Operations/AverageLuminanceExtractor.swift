#if os(Linux)
#if GLES
    import COpenGLES.gles2
    #else
    import COpenGL
#endif
#else
#if GLES
    import OpenGLES
    #else
    import OpenGL.GL3
#endif
#endif

public class AverageLuminanceExtractor: BasicOperation {
    public var extractedLuminanceCallback:((Float) -> ())?
    
    public init() {
        super.init(vertexShader:AverageColorVertexShader, fragmentShader:AverageLuminanceFragmentShader)
    }
    
    override func renderFrame() {
        // Reduce to luminance before passing into the downsampling
        // TODO: Combine this with the first stage of the downsampling by doing reduction here
        let luminancePassShader = crashOnShaderCompileFailure("AverageLuminance"){try sharedImageProcessingContext.programForVertexShader(defaultVertexShaderForInputs(1), fragmentShader:LuminanceFragmentShader)}
        let luminancePassFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:inputFramebuffers[0]!.orientation, size:inputFramebuffers[0]!.size)
        luminancePassFramebuffer.activateFramebufferForRendering()
        renderQuadWithShader(luminancePassShader, vertices:standardImageVertices, inputTextures:[inputFramebuffers[0]!.texturePropertiesForTargetOrientation(luminancePassFramebuffer.orientation)])
        
        averageColorBySequentialReduction(inputFramebuffer:luminancePassFramebuffer, shader:shader, extractAverageOperation:extractAverageLuminanceFromFramebuffer)
        releaseIncomingFramebuffers()
    }
    
    func extractAverageLuminanceFromFramebuffer(_ framebuffer:Framebuffer) {
        var data = [UInt8](repeating:0, count:Int(framebuffer.size.width * framebuffer.size.height * 4))
        glReadPixels(0, 0, framebuffer.size.width, framebuffer.size.height, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), &data)
        renderFramebuffer = framebuffer
        framebuffer.resetRetainCount()
        
        let totalNumberOfPixels = Int(framebuffer.size.width * framebuffer.size.height)
        
        var redTotal = 0
        for currentPixel in 0..<totalNumberOfPixels {
            redTotal += Int(data[currentPixel * 4])
        }
        
        extractedLuminanceCallback?(Float(redTotal) / Float(totalNumberOfPixels) / 255.0)
    }
}
