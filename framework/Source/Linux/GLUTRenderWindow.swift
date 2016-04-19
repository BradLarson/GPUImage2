import COpenGL
import CFreeGLUT

import Foundation

public class GLUTRenderWindow: ImageConsumer {
    public let sources = SourceContainer()
    public let maximumInputs:UInt = 1
    private lazy var displayShader:ShaderProgram = {
        sharedImageProcessingContext.makeCurrentContext()
        // self.openGLContext = sharedImageProcessingContext.context
        return crashOnShaderCompileFailure("GLUTRenderWindow"){try sharedImageProcessingContext.programForVertexShader(OneInputVertexShader, fragmentShader:PassthroughFragmentShader)}
    }()
	

	public init(width:UInt32, height:UInt32, title:String) {
	    var localArgc = Process.argc
	    glutInit(&localArgc, Process.unsafeArgv)
	    glutInitDisplayMode(UInt32(GLUT_DOUBLE))
	    glutInitWindowSize(Int32(width), Int32(height))
	    glutInitWindowPosition(100,100)
	    glutCreateWindow(title)
    
	    glViewport(0, 0, GLsizei(width), GLsizei(height))
	    glClearColor(0.15, 0.25, 0.35, 1.0)
	    glClear(GLenum(GL_COLOR_BUFFER_BIT))
		
		// glutReshapeFunc(void (*func)(int width, int height) // Maybe use this to get window reshape events
	}
	
    public func newFramebufferAvailable(framebuffer:Framebuffer, fromSourceIndex:UInt) {
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), 0)

		let width = glutGet(GLenum(GLUT_WINDOW_WIDTH))
		let height = glutGet(GLenum(GLUT_WINDOW_HEIGHT))
        glViewport(0, 0, GLint(width), GLint(height))

        glClearColor(0.0, 0.0, 0.0, 0.0)
        glClear(GLenum(GL_COLOR_BUFFER_BIT))

        renderQuadWithShader(self.displayShader, vertices:verticallyInvertedImageVertices, inputTextures:[framebuffer.texturePropertiesForTargetOrientation(.Portrait)])
		framebuffer.unlock()
	    glutSwapBuffers()
    }
	
	public func loopWithFunction(idleFunction:() -> ()) {
		loopFunction = idleFunction
	    glutIdleFunc(glutCallbackFunction)
	    glutMainLoop()
	}	
}

var loopFunction:(() -> ())! = nil

func glutCallbackFunction() {
	loopFunction()
}

