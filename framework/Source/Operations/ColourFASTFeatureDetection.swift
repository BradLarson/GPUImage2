/** This generates image-wide feature descriptors using the ColourFAST process, as developed and described in

 A. Ensor and S. Hall. ColourFAST: GPU-based feature point detection and tracking on mobile devices. 28th International Conference of Image and Vision Computing, New Zealand, 2013, p. 124-129.

 Seth Hall, "GPU accelerated feature algorithms for mobile devices", PhD thesis, School of Computing and Mathematical Sciences, Auckland University of Technology 2014.
 http://aut.researchgateway.ac.nz/handle/10292/7991
*/

// TODO: Have the blur radius and texel spacing be tied together into a general sampling distance scale factor
public class ColourFASTFeatureDetection: OperationGroup {
    public var blurRadiusInPixels:Float = 2.0 { didSet { boxBlur.blurRadiusInPixels = blurRadiusInPixels } }
    
    let boxBlur = BoxBlur()
    let colourFASTFeatureDescriptors = TextureSamplingOperation(vertexShader:ColourFASTDecriptorVertexShader, fragmentShader:ColourFASTDecriptorFragmentShader, numberOfInputs:2)
    
    public override init() {
        super.init()
        
        self.configureGroup{input, output in
            input --> self.colourFASTFeatureDescriptors
            input --> self.boxBlur --> self.colourFASTFeatureDescriptors --> output
        }
    }
}