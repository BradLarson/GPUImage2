import COpenGLES.gles2
import CVideoCore

import Foundation

var nativewindow = EGL_DISPMANX_WINDOW_T(element:0, width:0, height:0) // This needs to be retained at the top level or its deallocation will destroy the window system

public class RPiRenderWindow: ImageConsumer {
    public let sources = SourceContainer()
    public let maximumInputs:UInt = 1
    private lazy var displayShader:ShaderProgram = {
        sharedImageProcessingContext.makeCurrentContext()
        return crashOnShaderCompileFailure("RPiRenderWindow"){try sharedImageProcessingContext.programForVertexShader(OneInputVertexShader, fragmentShader:PassthroughFragmentShader)}
    }()
	
	let display:EGLDisplay
	let surface:EGLSurface
	let context:EGLContext
	
	let windowWidth:UInt32
	let windowHeight:UInt32

	public init(width:UInt32? = nil, height:UInt32? = nil) {
		sharedImageProcessingContext.makeCurrentContext()
	    display = eglGetDisplay(nil /* EGL_DEFAULT_DISPLAY */)
	    // guard (display != EGL_NO_DISPLAY) else {throw renderingError(errorString:"Could not obtain display")}
	    // guard (eglInitialize(display, nil, nil) != EGL_FALSE) else {throw renderingError(errorString:"Could not initialize display")}
	    eglInitialize(display, nil, nil)
    
	    let attributes:[EGLint] = [
	        EGL_RED_SIZE, 8,
	        EGL_GREEN_SIZE, 8,
	        EGL_BLUE_SIZE, 8,
	        EGL_ALPHA_SIZE, 8,
	        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
	        EGL_NONE
	    ]
		
	    var config:EGLConfig? = nil
	    var num_config:EGLint = 0
	    //	guard (eglChooseConfig(display, attributes, &config, 1, &num_config) != EGL_FALSE) else {throw renderingError(errorString:"Could not get a framebuffer configuration")}
	    eglChooseConfig(display, attributes, &config, 1, &num_config)
	    eglBindAPI(EGLenum(EGL_OPENGL_ES_API))
    
	    //context = eglCreateContext(display, config, EGL_NO_CONTEXT, context_attributes)
	    let context_attributes:[EGLint] = [
	        EGL_CONTEXT_CLIENT_VERSION, 2,
	        EGL_NONE
	    ]
	    context = eglCreateContext(display, config, nil /* EGL_NO_CONTEXT*/, context_attributes)
	    //guard (context != EGL_NO_CONTEXT) else {throw renderingError(errorString:"Could not create a rendering context")}
    
	    var screen_width:UInt32 = 0
	    var screen_height:UInt32 = 0
	    graphics_get_display_size(0 /* LCD */, &screen_width, &screen_height)
	    self.windowWidth = width ?? screen_width
	    self.windowHeight = height ?? screen_height
    
	    let dispman_display = vc_dispmanx_display_open( 0 /* LCD */)
	    let dispman_update = vc_dispmanx_update_start( 0 )
	    var dst_rect = VC_RECT_T(x:0, y:0, width:Int32(windowWidth), height:Int32(windowHeight))
	    var src_rect = VC_RECT_T(x:0, y:0, width:Int32(windowWidth) << 16, height:Int32(windowHeight) << 16)
    
	    let dispman_element = vc_dispmanx_element_add(dispman_update, dispman_display, 0/*layer*/, &dst_rect, 0/*src*/, &src_rect, DISPMANX_PROTECTION_T(DISPMANX_PROTECTION_NONE), nil /*alpha*/, nil/*clamp*/, DISPMANX_TRANSFORM_T(0)/*transform*/)
    
	    vc_dispmanx_update_submit_sync(dispman_update)
    
	    nativewindow = EGL_DISPMANX_WINDOW_T(element:dispman_element, width:Int32(windowWidth), height:Int32(windowHeight))
	    surface = eglCreateWindowSurface(display, config, &nativewindow, nil)
	    //guard (surface != EGL_NO_SURFACE) else {throw renderingError(errorString:"Could not create a rendering surface")}
    
	    eglMakeCurrent(display, surface, surface, context)
    
	    glViewport(0, 0, GLsizei(windowWidth), GLsizei(windowHeight))
	    glClearColor(0.15, 0.25, 0.35, 1.0)
	    glClear(GLenum(GL_COLOR_BUFFER_BIT))
	}
	
    public func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), 0)

        glViewport(0, 0, GLint(self.windowWidth), GLint(self.windowHeight))

        glClearColor(0.0, 0.0, 0.0, 0.0)
        glClear(GLenum(GL_COLOR_BUFFER_BIT))

        renderQuadWithShader(self.displayShader, vertices:verticallyInvertedImageVertices, inputTextures:[framebuffer.texturePropertiesForTargetOrientation(.portrait)])
		framebuffer.unlock()
	    eglSwapBuffers(display, surface)
    }
}