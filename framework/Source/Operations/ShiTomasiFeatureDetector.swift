/** Shi-Tomasi feature detector
 
 This is the Shi-Tomasi feature detector, as described in
 J. Shi and C. Tomasi. Good features to track. Proceedings of the IEEE Conference on Computer Vision and Pattern Recognition, pages 593-600, June 1994.
 */

public class ShiTomasiFeatureDetector: HarrisCornerDetector {
    public init() {
        super.init(fragmentShader:ShiTomasiFeatureDetectorFragmentShader)
    }
}