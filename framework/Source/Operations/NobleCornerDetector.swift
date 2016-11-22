/* Noble corner detector
 
 This is the Noble variant on the Harris detector, from
 Alison Noble, "Descriptions of Image Surfaces", PhD thesis, Department of Engineering Science, Oxford University 1989, p45.
*/

open class NobleCornerDetector: HarrisCornerDetector {
    public init() {
        super.init(fragmentShader:NobleCornerDetectorFragmentShader)
    }
}
