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

/* Harris corner detector
 
 First pass: reduce to luminance and take the derivative of the luminance texture (GPUImageXYDerivativeFilter)
 
 Second pass: blur the derivative (GaussianBlur)
 
 Third pass: apply the Harris corner detection calculation
 
 This is the Harris corner detector, as described in
 C. Harris and M. Stephens. A Combined Corner and Edge Detector. Proc. Alvey Vision Conf., Univ. Manchester, pp. 147-151, 1988.
*/

public class HarrisCornerDetector: OperationGroup {
    public var blurRadiusInPixels:Float = 2.0 { didSet { gaussianBlur.blurRadiusInPixels = blurRadiusInPixels } }
    public var sensitivity:Float = 5.0 { didSet { harrisCornerDetector.uniformSettings["sensitivity"] = sensitivity } }
    public var threshold:Float = 0.2 { didSet { nonMaximumSuppression.uniformSettings["threshold"] = threshold } }
    public var cornersDetectedCallback:(([Position]) -> ())?

    let xyDerivative = TextureSamplingOperation(fragmentShader:XYDerivativeFragmentShader)
    let gaussianBlur = GaussianBlur()
    let harrisCornerDetector:BasicOperation
    let nonMaximumSuppression = TextureSamplingOperation(fragmentShader:ThresholdedNonMaximumSuppressionFragmentShader)
    
    public init(fragmentShader:String = HarrisCornerDetectorFragmentShader) {
        harrisCornerDetector = BasicOperation(fragmentShader:fragmentShader)
        
        super.init()
        
        ({blurRadiusInPixels = 2.0})()
        ({sensitivity = 5.0})()
        ({threshold = 0.2})()
        
        outputImageRelay.newImageCallback = {[weak self] framebuffer in
            if let cornersDetectedCallback = self?.cornersDetectedCallback {
                cornersDetectedCallback(extractCornersFromImage(framebuffer))
            }
        }
        
        self.configureGroup{input, output in
            input --> self.xyDerivative --> self.gaussianBlur --> self.harrisCornerDetector --> self.nonMaximumSuppression --> output
        }
    }
}

func extractCornersFromImage(_ framebuffer:Framebuffer) -> [Position] {
    let imageByteSize = Int(framebuffer.size.width * framebuffer.size.height * 4)
//    var rawImagePixels = [UInt8](count:imageByteSize, repeatedValue:0)
    
//    let startTime = CFAbsoluteTimeGetCurrent()

    let rawImagePixels = UnsafeMutablePointer<UInt8>.allocate(capacity:imageByteSize)
    // -Onone, [UInt8] array: 30 ms for 720p frame on Retina iMac
    // -O, [UInt8] array: 4 ms for 720p frame on Retina iMac
    // -Onone, UnsafeMutablePointer<UInt8>: 7 ms for 720p frame on Retina iMac
    // -O, UnsafeMutablePointer<UInt8>: 4 ms for 720p frame on Retina iMac

//    glReadPixels(0, 0, framebuffer.size.width, framebuffer.size.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &rawImagePixels)
    glReadPixels(0, 0, framebuffer.size.width, framebuffer.size.height, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), rawImagePixels)

    let imageWidth = Int(framebuffer.size.width * 4)
    
    var corners = [Position]()
    
    var currentByte = 0
    while (currentByte < imageByteSize) {
        let colorByte = rawImagePixels[currentByte]
        
        if (colorByte > 0) {
            let xCoordinate = currentByte % imageWidth
            let yCoordinate = currentByte / imageWidth
            
            corners.append(Position(((Float(xCoordinate) / 4.0) / Float(framebuffer.size.width)), Float(yCoordinate) / Float(framebuffer.size.height)))
        }
        currentByte += 4
    }
    
    rawImagePixels.deallocate(capacity:imageByteSize)

//    print("Harris extraction frame time: \(CFAbsoluteTimeGetCurrent() - startTime)")

    return corners
}
