/** This applies the edge detection process described by John Canny in
 
 Canny, J., A Computational Approach To Edge Detection, IEEE Trans. Pattern Analysis and Machine Intelligence, 8(6):679–698, 1986.
 
 and implemented in OpenGL ES by
 
 A. Ensor, S. Hall. GPU-based Image Analysis on Mobile Devices. Proceedings of Image and Vision Computing New Zealand 2011.
 
 It starts with a conversion to luminance, followed by an accelerated 9-hit Gaussian blur. A Sobel operator is applied to obtain the overall
 gradient strength in the blurred image, as well as the direction (in texture sampling steps) of the gradient. A non-maximum suppression filter
 acts along the direction of the gradient, highlighting strong edges that pass the threshold and completely removing those that fail the lower
 threshold. Finally, pixels from in-between these thresholds are either included in edges or rejected based on neighboring pixels.
 */

public class CannyEdgeDetection: OperationGroup {
    public var blurRadiusInPixels:Float = 2.0 { didSet { gaussianBlur.blurRadiusInPixels = blurRadiusInPixels } }
    public var upperThreshold:Float = 0.4 { didSet { directionalNonMaximumSuppression.uniformSettings["upperThreshold"] = upperThreshold } }
    public var lowerThreshold:Float = 0.1 { didSet { directionalNonMaximumSuppression.uniformSettings["lowerThreshold"] = lowerThreshold } }
    
    let luminance = Luminance()
    let gaussianBlur = SingleComponentGaussianBlur()
    let directionalSobel = TextureSamplingOperation(fragmentShader:DirectionalSobelEdgeDetectionFragmentShader)
    let directionalNonMaximumSuppression = TextureSamplingOperation(vertexShader:OneInputVertexShader, fragmentShader:DirectionalNonMaximumSuppressionFragmentShader)
    let weakPixelInclusion = TextureSamplingOperation(fragmentShader:WeakPixelInclusionFragmentShader)
    
    public override init() {
        super.init()
        
        ({blurRadiusInPixels = 2.0})()
        ({upperThreshold = 0.4})()
        ({lowerThreshold = 0.1})()
        
        self.configureGroup{input, output in
            input --> self.luminance --> self.gaussianBlur --> self.directionalSobel --> self.directionalNonMaximumSuppression --> self.weakPixelInclusion --> output
        }
    }
}