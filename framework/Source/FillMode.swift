#if os(Linux)
import Glibc
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


public enum FillMode {
    case Stretch
    case PreserveAspectRatio
    case PreserveAspectRatioAndFill
    
    func transformVertices(vertices:[GLfloat], fromInputSize:GLSize, toFitSize:GLSize) -> [GLfloat] {
        guard (vertices.count == 8) else { fatalError("Attempted to transform a non-quad to account for fill mode.") }
        
        let aspectRatio = GLfloat(fromInputSize.height) / GLfloat(fromInputSize.width)
        let targetAspectRatio = GLfloat(toFitSize.height) / GLfloat(toFitSize.width)
        
        let yRatio:GLfloat
        let xRatio:GLfloat
        switch self {
            case Stretch: return vertices
            case PreserveAspectRatio:
                if (aspectRatio > targetAspectRatio) {
                    yRatio = 1.0
//                    xRatio = (GLfloat(toFitSize.height) / GLfloat(fromInputSize.height)) * (GLfloat(fromInputSize.width) / GLfloat(toFitSize.width))
                    xRatio = (GLfloat(fromInputSize.width) / GLfloat(toFitSize.width)) * (GLfloat(toFitSize.height) / GLfloat(fromInputSize.height))
                } else {
                    xRatio = 1.0
                    yRatio = (GLfloat(fromInputSize.height) / GLfloat(toFitSize.height)) * (GLfloat(toFitSize.width) / GLfloat(fromInputSize.width))
                }
            case PreserveAspectRatioAndFill:
                if (aspectRatio > targetAspectRatio) {
                    xRatio = 1.0
                    yRatio = (GLfloat(fromInputSize.height) / GLfloat(toFitSize.height)) * (GLfloat(toFitSize.width) / GLfloat(fromInputSize.width))
                } else {
                    yRatio = 1.0
                    xRatio = (GLfloat(toFitSize.height) / GLfloat(fromInputSize.height)) * (GLfloat(fromInputSize.width) / GLfloat(toFitSize.width))
            }
        }
        // Pixel-align to output dimensions
//        return [vertices[0] * xRatio, vertices[1] * yRatio, vertices[2] * xRatio, vertices[3] * yRatio, vertices[4] * xRatio, vertices[5] * yRatio, vertices[6] * xRatio, vertices[7] * yRatio]
        // TODO: Determine if this is misaligning things
        
		let xConversionRatio:GLfloat = xRatio * GLfloat(toFitSize.width) / 2.0
		let xConversionDivisor:GLfloat = GLfloat(toFitSize.width) / 2.0
		let yConversionRatio:GLfloat = yRatio * GLfloat(toFitSize.height) / 2.0
		let yConversionDivisor:GLfloat = GLfloat(toFitSize.height) / 2.0

		// The Double casting here is required by Linux
        return [GLfloat(round(Double(vertices[0] * xConversionRatio))) / xConversionDivisor, GLfloat(round(Double(vertices[1] * yConversionRatio))) / yConversionDivisor,
                GLfloat(round(Double(vertices[2] * xConversionRatio))) / xConversionDivisor, GLfloat(round(Double(vertices[3] * yConversionRatio))) / yConversionDivisor,
                GLfloat(round(Double(vertices[4] * xConversionRatio))) / xConversionDivisor, GLfloat(round(Double(vertices[5] * yConversionRatio))) / yConversionDivisor,
                GLfloat(round(Double(vertices[6] * xConversionRatio))) / xConversionDivisor, GLfloat(round(Double(vertices[7] * yConversionRatio))) / yConversionDivisor]
    }
}
