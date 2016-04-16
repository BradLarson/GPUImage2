public class HighPassFilter: OperationGroup {
    public var strength: Float = 0.5 { didSet { lowPass.strength = strength } }
    
    let lowPass = LowPassFilter()
    let differenceBlend = DifferenceBlend()
    
    public override init() {
        super.init()
        
        ({strength = 0.5})()
        
        self.configureGroup{input, output in
            input --> self.differenceBlend
            input --> self.lowPass --> self.differenceBlend --> output
        }
    }
}