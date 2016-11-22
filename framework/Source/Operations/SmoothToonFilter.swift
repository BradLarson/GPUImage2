open class SmoothToonFilter: OperationGroup {
    open var blurRadiusInPixels: Float = 2.0 { didSet { gaussianBlur.blurRadiusInPixels = blurRadiusInPixels } }
    open var threshold: Float = 0.2 { didSet { toonFilter.threshold = threshold } }
    open var quantizationLevels: Float = 10.0 { didSet { toonFilter.quantizationLevels = quantizationLevels } }

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
