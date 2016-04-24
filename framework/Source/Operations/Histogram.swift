#if os(Linux)
#if GLES
    import COpenGLES.gles2
let GL_DEPTH24_STENCIL8 = GL_DEPTH24_STENCIL8_OES
let GL_TRUE = GLboolean(1)
let GL_FALSE = GLboolean(0)
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

public enum HistogramType {
    case Red
    case Blue
    case Green
    case Luminance
    case RGB
}

public class Histogram: BasicOperation {
    public var downsamplingFactor:UInt = 16
    
    var shader2:ShaderProgram? = nil
    var shader3:ShaderProgram? = nil
    
    public init(type:HistogramType) {
        switch type {
            case .Red: super.init(vertexShader:HistogramRedSamplingVertexShader, fragmentShader:HistogramAccumulationFragmentShader, numberOfInputs:1)
            case .Blue: super.init(vertexShader:HistogramBlueSamplingVertexShader, fragmentShader:HistogramAccumulationFragmentShader, numberOfInputs:1)
            case .Green: super.init(vertexShader:HistogramGreenSamplingVertexShader, fragmentShader:HistogramAccumulationFragmentShader, numberOfInputs:1)
            case .Luminance: super.init(vertexShader:HistogramLuminanceSamplingVertexShader, fragmentShader:HistogramAccumulationFragmentShader, numberOfInputs:1)
            case .RGB:
                super.init(vertexShader:HistogramRedSamplingVertexShader, fragmentShader:HistogramAccumulationFragmentShader, numberOfInputs:1)
                shader2 = crashOnShaderCompileFailure("Histogram"){try sharedImageProcessingContext.programForVertexShader(HistogramGreenSamplingVertexShader, fragmentShader:HistogramAccumulationFragmentShader)}
                shader3 = crashOnShaderCompileFailure("Histogram"){try sharedImageProcessingContext.programForVertexShader(HistogramBlueSamplingVertexShader, fragmentShader:HistogramAccumulationFragmentShader)}
        }
    }
    
    override func renderFrame() {
        let inputSize = sizeOfInitialStageBasedOnFramebuffer(inputFramebuffers[0]!)
        let inputByteSize = Int(inputSize.width * inputSize.height * 4)
        let data = UnsafeMutablePointer<UInt8>.alloc(inputByteSize)
        glReadPixels(0, 0, inputSize.width, inputSize.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), data)

        renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.Portrait, size:GLSize(width:256, height:3), stencil:mask != nil)
        releaseIncomingFramebuffers()
        renderFramebuffer.activateFramebufferForRendering()
        
        clearFramebufferWithColor(Color.Black)

        glBlendEquation(GLenum(GL_FUNC_ADD))
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE))
        glEnable(GLenum(GL_BLEND))

        shader.use()
        guard let positionAttribute = shader.attributeIndex("position") else { fatalError("A position attribute was missing from the shader program during rendering.") }
        glVertexAttribPointer(positionAttribute, 4, GLenum(GL_UNSIGNED_BYTE), 0, (GLint(downsamplingFactor) - 1) * 4, data)
        glDrawArrays(GLenum(GL_POINTS), 0, inputSize.width * inputSize.height / GLint(downsamplingFactor))

        if let shader2 = shader2 {
            shader2.use()
            guard let positionAttribute2 = shader.attributeIndex("position") else { fatalError("A position attribute was missing from the shader program during rendering.") }
            glVertexAttribPointer(positionAttribute2, 4, GLenum(GL_UNSIGNED_BYTE), 0, (GLint(downsamplingFactor) - 1) * 4, data)
            glDrawArrays(GLenum(GL_POINTS), 0, inputSize.width * inputSize.height / GLint(downsamplingFactor))
        }

        if let shader3 = shader3 {
            shader3.use()
            guard let positionAttribute3 = shader.attributeIndex("position") else { fatalError("A position attribute was missing from the shader program during rendering.") }
            glVertexAttribPointer(positionAttribute3, 4, GLenum(GL_UNSIGNED_BYTE), 0, (GLint(downsamplingFactor) - 1) * 4, data)
            glDrawArrays(GLenum(GL_POINTS), 0, inputSize.width * inputSize.height / GLint(downsamplingFactor))
        }

        glDisable(GLenum(GL_BLEND))
        data.dealloc(inputByteSize)
    }
}