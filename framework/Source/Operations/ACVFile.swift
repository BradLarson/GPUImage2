import Foundation

public class ACVFile {
    fileprivate var version: UInt16
    fileprivate var curvesCount: UInt16
    
    public var redControlPoints: [Position]
    public var greenControlPoints: [Position]
    public var blueControlPoints: [Position]
    public var rgbCompositeControlPoints: [Position]
    
    public convenience init?(fileName: String) throws {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "acv") else {
            return nil
        }
        let data = try Data(contentsOf: url)
        self.init(data: data)
    }
    
    public init?(data: Data) {
        guard data.count > 0 else { return nil }
        let stepSize = 2
        
        var offset = 0
        self.version = data.scanValue(start: offset, length: stepSize)
        offset += stepSize
        
        self.curvesCount = data.scanValue(start: offset, length: stepSize)
        offset += stepSize
        
        let pointRate: Float = 1.0 / 255
        
        var curves: [[Position]] = []
        
        for _ in 0 ..< curvesCount {
            let pointCount = data.scanValue(start: offset, length: stepSize)
            offset += stepSize
            
            var points = [Position]()
            
            for _ in 0 ..< pointCount {
                let y = data.scanValue(start: offset, length: stepSize)
                offset += stepSize
                let x = data.scanValue(start: offset, length: stepSize)
                offset += stepSize
                
                points.append(Position(Float(x) * pointRate, Float(y) * pointRate))
            }
            curves.append(points)
        }
        self.rgbCompositeControlPoints = curves[0]
        self.redControlPoints = curves[1]
        self.greenControlPoints = curves[2]
        self.blueControlPoints = curves[3]
    }
}

extension Data {
    fileprivate func scanValue(start: Int, length: Int) -> UInt16 {
        var bytes = [UInt8](repeating: 0, count: count)
        copyBytes(to: &bytes, count: count)
        
        let slice = Array(bytes[start ..< start + length])
        let u16raw = UnsafePointer(slice).withMemoryRebound(to: UInt16.self, capacity: length) { $0.pointee }
        let u16 = CFSwapInt16BigToHost(u16raw)
        
        return u16
    }
}
