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


public class CircleGenerator: ImageGenerator {
    let circleShader:ShaderProgram
    
    public override init(size:Size) {
        circleShader = crashOnShaderCompileFailure("CircleGenerator"){try sharedImageProcessingContext.programForVertexShader(CircleVertexShader, fragmentShader:CircleFragmentShader)}
        circleShader.colorUniformsUseFourComponents = true
        super.init(size:size)
    }

    public func renderCircleOfRadius(_ radius:Float, center:Position, circleColor:Color = Color.white, backgroundColor:Color = Color.black) {
        let scaledRadius = radius * 2.0
        imageFramebuffer.activateFramebufferForRendering()
        var uniformSettings = ShaderUniformSettings()
        uniformSettings["circleColor"] = circleColor
        uniformSettings["backgroundColor"] = backgroundColor
        uniformSettings["radius"] = scaledRadius
        uniformSettings["aspectRatio"] = imageFramebuffer.aspectRatioForRotation(.noRotation)
        
        let convertedCenterX = (Float(center.x) * 2.0) - 1.0
        let convertedCenterY = (Float(center.y) * 2.0) - 1.0
        let scaledYRadius = scaledRadius / imageFramebuffer.aspectRatioForRotation(.noRotation)

        uniformSettings["center"] = Position(convertedCenterX, convertedCenterY)
        let circleVertices:[GLfloat] = [GLfloat(convertedCenterX - scaledRadius), GLfloat(convertedCenterY - scaledYRadius), GLfloat(convertedCenterX + scaledRadius), GLfloat(convertedCenterY - scaledYRadius), GLfloat(convertedCenterX - scaledRadius), GLfloat(convertedCenterY + scaledYRadius), GLfloat(convertedCenterX + scaledRadius), GLfloat(convertedCenterY + scaledYRadius)]
        
        clearFramebufferWithColor(backgroundColor)
        circleShader.use()
        uniformSettings.restoreShaderSettings(circleShader)
        
        guard let positionAttribute = circleShader.attributeIndex("position") else { fatalError("A position attribute was missing from the shader program during rendering.") }
        glVertexAttribPointer(positionAttribute, 2, GLenum(GL_FLOAT), 0, 0, circleVertices)
        
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        
        notifyTargets()
    }
}
