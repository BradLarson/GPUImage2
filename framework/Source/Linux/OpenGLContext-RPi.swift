import COpenGLES.gles2
import CVideoCore

class OpenGLContext {
    lazy var framebufferCache:FramebufferCache = {
        return FramebufferCache(context:self)
    }()
    var shaderCache:[String:ShaderProgram] = [:]
    
    lazy var passthroughShader:ShaderProgram = {
        return crashOnShaderCompileFailure("OpenGLContext"){return try self.programForVertexShader(OneInputVertexShader, fragmentShader:PassthroughFragmentShader)}
    }()
	
    // MARK: -
    // MARK: Initialization and teardown

    init() {
	    bcm_host_init()
        
        glDisable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_TEXTURE_2D))
    }
    
    // MARK: -
    // MARK: Rendering
    
    func makeCurrentContext() {
    }
    
    func presentBufferForDisplay() {
    }    
}