public class SmoothToonFilter: OperationGroup {
    public var blurRadiusInPixels: Float = 2.0 { didSet { gaussianBlur.blurRadiusInPixels = blurRadiusInPixels } }
    public var threshold: Float = 0.2 { didSet { toonFilter.threshold = threshold } }
    public var quantizationLevels: Float = 10.0 { didSet { toonFilter.quantizationLevels = quantizationLevels } }

    let gaussianBlur = GaussianBlur()
    let toonFilter = ToonFilter()

    public override init() {
        super.init()

        ({blurRadiusInPixels = 2.0})()
        ({threshold = 0.2})()
        ({quantizationLevels = 10.0})()

        self.configureGroup{input, output in
            input --> self.gaussianBlur --> self.toonFilter --> output
        }
    }
}