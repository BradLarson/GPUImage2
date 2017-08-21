/// Small helper class for MotionDetection and detection visualisation
public class ObjectMotionDetector: OperationGroup {
    public var lowPassStrength:Float = 1.0 { didSet {lowPassFilter.strength = lowPassStrength}}
    public var threshold:Float = 0.2 { didSet {motionComparison.treshold = threshold}}
    public var motionDetectedCallback:((Position, Float) -> ())?
    
    fileprivate let lowPassFilter = LowPassFilter()
    fileprivate let motionComparison = MotionComparison()
    fileprivate let averageColorExtractor = AverageColorExtractor()
    fileprivate lazy var outputRelay = ImageRelay()
    
    public override init() {
        super.init()
        
        averageColorExtractor.extractedColorCallback = {[weak self] color in
            let position = Position(color.redComponent / color.alphaComponent,
                                    color.greenComponent / color.alphaComponent)
            self?.motionDetectedCallback?(position, color.alphaComponent)
        }
        
        self.configureGroup { input, output in
            input --> self.motionComparison --> self.averageColorExtractor --> self.outputRelay
            input --> self.lowPassFilter --> self.motionComparison --> output
        }
    }
}
