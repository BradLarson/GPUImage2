public class HistogramEqualization: OperationGroup {
    public var downsamplingFactor: UInt = 16 { didSet { histogram.downsamplingFactor = downsamplingFactor } }
    
    let histogram:Histogram
    let rawDataInput = RawDataInput()
    let rawDataOutput = RawDataOutput()
    let equalizationFilter:BasicOperation
    
    public init(type:HistogramType) {
        
        self.histogram = Histogram(type:type)
        switch type {
            case .red: self.equalizationFilter = BasicOperation(fragmentShader:HistogramEqualizationRedFragmentShader, numberOfInputs:2)
            case .blue: self.equalizationFilter = BasicOperation(fragmentShader:HistogramEqualizationBlueFragmentShader, numberOfInputs:2)
            case .green: self.equalizationFilter = BasicOperation(fragmentShader:HistogramEqualizationGreenFragmentShader, numberOfInputs:2)
            case .luminance:  self.equalizationFilter = BasicOperation(fragmentShader:HistogramEqualizationLuminanceFragmentShader, numberOfInputs:2)
            case .rgb: self.equalizationFilter = BasicOperation(fragmentShader:HistogramEqualizationRGBFragmentShader, numberOfInputs:2)
        }

        super.init()
        
        ({downsamplingFactor = 16})()
        
        self.configureGroup{input, output in
            self.rawDataOutput.dataAvailableCallback = {data in
                var redHistogramBin = [Int](repeating:0, count:256)
                var greenHistogramBin = [Int](repeating:0, count:256)
                var blueHistogramBin = [Int](repeating:0, count:256)

                let rowWidth = 256 * 4
                redHistogramBin[0] = Int(data[rowWidth])
                greenHistogramBin[1] = Int(data[rowWidth + 1])
                blueHistogramBin[2] = Int(data[rowWidth + 2])
                
                for dataIndex in 1..<256 {
                    redHistogramBin[dataIndex] = redHistogramBin[dataIndex - 1] + Int(data[rowWidth + (dataIndex * 4)])
                    greenHistogramBin[dataIndex] = greenHistogramBin[dataIndex - 1] + Int(data[rowWidth + (dataIndex * 4) + 1])
                    blueHistogramBin[dataIndex] = blueHistogramBin[dataIndex - 1] + Int(data[rowWidth + (dataIndex * 4) + 2])
                }
                
                var equalizationLookupTable = [UInt8](repeating:0, count:256 * 4)
                for binIndex in 0..<256 {
                    equalizationLookupTable[binIndex * 4] = UInt8((((redHistogramBin[binIndex] - redHistogramBin[0]) * 255) / redHistogramBin[255]))
                    equalizationLookupTable[(binIndex * 4) + 1] = UInt8((((greenHistogramBin[binIndex] - greenHistogramBin[0]) * 255) / greenHistogramBin[255]))
                    equalizationLookupTable[(binIndex * 4) + 2] = UInt8((((blueHistogramBin[binIndex] - blueHistogramBin[0]) * 255) / blueHistogramBin[255]))
                    equalizationLookupTable[(binIndex * 4) + 3] = 255
                }
                
                self.rawDataInput.uploadBytes(equalizationLookupTable, size:Size(width:256, height:1), pixelFormat:.rgba)
            }
            
            input --> self.histogram --> self.rawDataOutput
            input --> self.equalizationFilter --> output
            self.rawDataInput --> self.equalizationFilter
        }
    }
}
