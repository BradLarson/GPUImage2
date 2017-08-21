public class MotionDetector: OperationGroup {
    public var lowPassStrength:Float = 1.0 { didSet {lowPassFilter.strength = lowPassStrength}}
    public var treshold:Float = 0.2 { didSet {motionComparison.treshold = treshold}}
    public var motionDetectedCallback:((Position, Float) -> ())?
    
    let lowPassFilter = LowPassFilter()
    let motionComparison = MotionComparison()
    let averageColorExtractor = AverageColorExtractor()
    
    public override init() {
        super.init()
        
        averageColorExtractor.extractedColorCallback = {[weak self] color in
            self?.motionDetectedCallback?(Position(color.redComponent / color.alphaComponent, color.greenComponent / color.alphaComponent), color.alphaComponent)
        }
        
        self.configureGroup{input, output in
            input --> self.motionComparison --> self.averageColorExtractor --> output
            input --> self.lowPassFilter --> self.motionComparison
        }
    }
}
