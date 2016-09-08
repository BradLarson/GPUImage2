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
    import OpenGL.GL
#endif
#endif

public class CrosshairGenerator: ImageGenerator {
    
    public var crosshairWidth:Float = 5.0 { didSet { uniformSettings["crosshairWidth"] = crosshairWidth } }
    public var crosshairColor:Color = Color.green { didSet { uniformSettings["crosshairColor"] = crosshairColor } }

    let crosshairShader:ShaderProgram
    var uniformSettings = ShaderUniformSettings()

    public override init(size:Size) {        
        crosshairShader = crashOnShaderCompileFailure("CrosshairGenerator"){try sharedImageProcessingContext.programForVertexShader(CrosshairVertexShader, fragmentShader:CrosshairFragmentShader)}
        super.init(size:size)
        
        ({crosshairWidth = 5.0})()
        ({crosshairColor = Color.green})()
    }
    

    public func renderCrosshairs(_ positions:[Position]) {
        imageFramebuffer.activateFramebufferForRendering()
        imageFramebuffer.timingStyle = .stillImage
#if GL
        glEnable(GLenum(GL_POINT_SPRITE))
        glEnable(GLenum(GL_VERTEX_PROGRAM_POINT_SIZE))
#else
        glEnable(GLenum(GL_POINT_SPRITE_OES))
#endif

        crosshairShader.use()
        uniformSettings.restoreShaderSettings(crosshairShader)

        clearFramebufferWithColor(Color.transparent)
        
        guard let positionAttribute = crosshairShader.attributeIndex("position") else { fatalError("A position attribute was missing from the shader program during rendering.") }

        let convertedPositions = positions.flatMap{$0.toGLArray()}
        glVertexAttribPointer(positionAttribute, 2, GLenum(GL_FLOAT), 0, 0, convertedPositions)
        
        glDrawArrays(GLenum(GL_POINTS), 0, GLsizei(positions.count))

        notifyTargets()
    }
}
