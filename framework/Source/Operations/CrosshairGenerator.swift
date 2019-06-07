#if canImport(OpenGL)
import OpenGL.GL
#endif

#if canImport(OpenGLES)
import OpenGLES
#endif

#if canImport(COpenGLES)
import COpenGLES.gles2
#endif

#if canImport(COpenGL)
import COpenGL
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
#if canImport(OpenGL) || canImport(COpenGL)
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
