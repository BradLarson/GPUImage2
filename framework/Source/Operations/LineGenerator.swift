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

public enum Line {
    case Infinite(slope:Float, intercept:Float)
    case Segment(p1:Position, p2:Position)

    func toGLEndpoints() -> [GLfloat] {
        switch self {
        case .Infinite(let slope, let intercept):
            if (slope > 9000.0) {// Vertical line
                return [intercept, -1.0, intercept, 1.0]
            } else {
                return [-1.0, GLfloat(slope * -1.0 + intercept), 1.0, GLfloat(slope * 1.0 + intercept)]
            }
        case .Segment(let p1, let p2):
            return [p1.x, p1.y, p2.x, p2.y].map {GLfloat($0)}
        }
    }
}

public class LineGenerator: ImageGenerator {
    public var lineColor:Color = Color.Green { didSet { uniformSettings["lineColor"] = lineColor } }
    public var lineWidth:Float = 1.0 {
        didSet {
            lineShader.use()
            glLineWidth(lineWidth)
        }
    }
    
    let lineShader:ShaderProgram
    var uniformSettings = ShaderUniformSettings()
    
    public override init(size:Size) {
        lineShader = crashOnShaderCompileFailure("LineGenerator"){try sharedImageProcessingContext.programForVertexShader(LineVertexShader, fragmentShader:LineFragmentShader)}
        super.init(size:size)
        
        ({lineWidth = 1.0})()
        ({lineColor = Color.Red})()
    }

    public func renderLines(lines:[Line]) {
        imageFramebuffer.activateFramebufferForRendering()
        
        lineShader.use()
        uniformSettings.restoreShaderSettings(lineShader)
        
        clearFramebufferWithColor(Color.Transparent)
        
        guard let positionAttribute = lineShader.attributeIndex("position") else { fatalError("A position attribute was missing from the shader program during rendering.") }
        
        let lineEndpoints = lines.flatMap{$0.toGLEndpoints()}
        glVertexAttribPointer(positionAttribute, 2, GLenum(GL_FLOAT), 0, 0, lineEndpoints)
        
        glBlendEquation(GLenum(GL_FUNC_ADD))
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE))
        glEnable(GLenum(GL_BLEND))

        glDrawArrays(GLenum(GL_LINES), 0, GLsizei(lines.count) * 2)

        glDisable(GLenum(GL_BLEND))

        notifyTargets()
    }

}