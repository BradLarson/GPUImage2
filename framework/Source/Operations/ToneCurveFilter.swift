#if os(Linux)
#if GLES
    import COpenGLES.gles2
#else
    import COpenGL
#endif
#else
#if GLES
    import OpenGLES
#else
    import OpenGL.GL3
#endif
#endif
import Foundation

public class ToneCurveFilter: BasicOperation {

    public var redControlPoints: [Position] {
        didSet {
            redCurve = getPreparedSplineCurve(points: redControlPoints) ?? []
            updateToneCurveTexture()
        }
    }
    public var greenControlPoints: [Position] {
        didSet {
            greenCurve = getPreparedSplineCurve(points: greenControlPoints) ?? []
            updateToneCurveTexture()
        }
    }
    public var blueControlPoints: [Position] {
        didSet {
            blueCurve = getPreparedSplineCurve(points: blueControlPoints) ?? []
            updateToneCurveTexture()
        }
    }
    public var rgbCompositeControlPoints: [Position] {
        didSet {
            rgbCompositeCurve = getPreparedSplineCurve(points: rgbCompositeControlPoints) ?? []
            updateToneCurveTexture()
        }
    }
    
    fileprivate var toneCurveTexture: GLuint = 0
    fileprivate var toneCurveByteArray: [GLubyte] = []
    
    fileprivate var redCurve: [Float] = []
    fileprivate var greenCurve: [Float] = []
    fileprivate var blueCurve: [Float] = []
    fileprivate var rgbCompositeCurve: [Float] = []
    
    public init() {
        let curve = [Position(0, 0), Position(0.5, 0.5), Position(1, 1)]
        
        self.redControlPoints = curve
        self.greenControlPoints = curve
        self.blueControlPoints = curve
        self.rgbCompositeControlPoints = curve
        
        super.init(fragmentShader: ToneCurveFragmentShader, numberOfInputs: 1)
        
        ({redControlPoints = curve})()
        ({greenControlPoints = curve})()
        ({blueControlPoints = curve})()
        ({rgbCompositeControlPoints = curve})()
    }
    
    public convenience init?(fileName: String) throws {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "acv") else {
            return nil
        }
        try self.init(fileUrl: url)
    }
    
    public convenience init?(fileUrl: URL) throws {
        let data = try Data(contentsOf: fileUrl)
        self.init(acvData: data)
    }
    
    public init?(acvData: Data) {
        guard let curve = ACVFile(data: acvData) else {
            return nil
        }
        
        self.redControlPoints = curve.redControlPoints
        self.greenControlPoints = curve.greenControlPoints
        self.blueControlPoints = curve.blueControlPoints
        self.rgbCompositeControlPoints = curve.rgbCompositeControlPoints
        
        super.init(fragmentShader: ToneCurveFragmentShader, numberOfInputs: 1)
        
        ({redControlPoints = curve.redControlPoints})()
        ({greenControlPoints = curve.greenControlPoints})()
        ({blueControlPoints = curve.blueControlPoints})()
        ({rgbCompositeControlPoints = curve.rgbCompositeControlPoints})()
    }
    
    deinit {
        glDeleteTextures(1, &toneCurveTexture)
        toneCurveTexture = 0
    }
    
    // MARK Curve calculation
    
    func secondDerivative(_ points: [Position]) -> [Float]? {
        guard points.count > 1 else { return nil }
        
        let n = points.count
        var matrix: [[Float]] = Array(repeatElement(Array(repeatElement(0, count: 3)), count: n))
        var result: [Float] = Array(repeatElement(0, count: n))
        
        matrix[0][0] = 0
        matrix[0][1] = 1
        matrix[0][2] = 0
        
        for i in 1 ..< n - 1 {
            let p1 = points[i - 1]
            let p2 = points[i]
            let p3 = points[i + 1]
            
            matrix[i][0] = (p2.x - p1.x) / 6
            matrix[i][1] = (p3.x - p1.x) / 3
            matrix[i][2] = (p3.x - p2.x) / 6
            result[i] = (p3.y - p2.y) / (p3.x - p2.x) - (p2.y - p1.y) / (p2.x - p1.x)
        }
        result[0] = 0
        result[n - 1] = 0
    
        matrix[n - 1][1] = 1
        matrix[n - 1][0] = 0
        matrix[n - 1][2] = 0
    
        // solving pass1 (up->down)
        for i in 1 ..< n {
            let k = matrix[i][0] / matrix[i - 1][1]
            matrix[i][1] -= k * matrix[i - 1][2]
            matrix[i][0] = 0
            result[i] -= k * result[i - 1]
        }
        // solving pass2 (down->up)
        for i in (0 ... n - 2).reversed() {
            let k = matrix[i][2] / matrix[i + 1][1]
            matrix[i][1] -= k * matrix[i + 1][0]
            matrix[i][2] = 0
            result[i] -= k * result[i + 1]
        }
        
        var y2: [Float] = Array(repeatElement(0, count: n))
        for i in 0 ..< n {
            y2[i] = result[i] / matrix[i][1]
        }
        
        return y2
    }
    
    
    func splineCurve(points: [Position]) -> [Position]? {
        guard let sdA = secondDerivative(points), sdA.count >= 1 else {
            return nil
        }
        let n = sdA.count
        var sd = sdA
        
        var output: [Position] = []
        
        for i in 0 ..< n - 1 {
            let current = points[i]
            let next = points[i + 1]
            
            var x = Int(current.x)
            repeat {
                let t = (Float(x) - current.x) / (next.x - current.x)
                let a = 1 - t
                let b = t
                let h = next.x - current.x
                
                let aFactor = (a * a * a - a) * sd[i]
                let bFactor = (b * b * b - b) * sd[i + 1]
                var y = a * current.y + b * next.y + (h * h / 6) * (aFactor + bFactor)
                if y > 255 {
                    y = 255
                } else if y < 0 {
                    y = 0
                }
                
                output.append(Position(Float(x), y))
                x += 1
            } while x < Int(next.x)
        }
        // The above always misses the last point because the last point is the last next, so we approach but don't equal it.
        output.append(points.last!)
    
        return output
    }
    
    func getPreparedSplineCurve(points: [Position]) -> [Float]? {
        guard points.count > 0 else { return nil }
        let sortedPoints = points.sorted { $0.x < $1.x }
        
        // Convert from (0, 1) to (0, 255).
        let convertedPoints = sortedPoints.map { point in
            return Position(point.x * 255, point.y * 255)
        }
        
        guard var splinePoints = splineCurve(points: convertedPoints) else { return nil }
        
        // If we have a first point like (0.3, 0) we'll be missing some points at the beginning
        // that should be 0.
        let firstSplinePoint = splinePoints.first!
        
        if firstSplinePoint.x > 0 {
            for i in (0 ... Int(firstSplinePoint.x)).reversed() {
                let newPoint = Position(Float(i), 0)
                splinePoints.insert(newPoint, at: 0)
            }
        }
        
        // Insert points similarly at the end, if necessary.
        let lastSplinePoint = splinePoints.last!
        
        if lastSplinePoint.x < 255 {
            for i in Int(lastSplinePoint.x + 1) ... 255 {
                let newPoint = Position(Float(i), 255)
                splinePoints.append(newPoint)
            }
        }
        
        // Prepare the spline points.
        let preparedSplinePoints = splinePoints.compactMap { (point: Position) -> Float in
            let origPoint = Position(point.x, point.x)
            var distance = sqrt(pow(origPoint.x - point.x, 2) + pow(origPoint.y - point.y, 2))
            if origPoint.y > point.y {
                distance = -distance
            }
            return distance
        }
        return preparedSplinePoints
    }
    
    override func internalRenderFunction(_ inputFramebuffer: Framebuffer, textureProperties: [InputTextureProperties]) {
        renderQuadWithShader(shader, uniformSettings:uniformSettings, vertexBufferObject:sharedImageProcessingContext.standardImageVBO, inputTextures:textureProperties)
        
        glActiveTexture(GLenum(GL_TEXTURE3))
        glBindTexture(GLenum(GL_TEXTURE_2D), toneCurveTexture)
        shader.setValue(GLint(3), forUniform:"toneCurveTexture")
        
        releaseIncomingFramebuffers()
    }
    
    func updateToneCurveTexture() {
        sharedImageProcessingContext.runOperationSynchronously {
            if toneCurveTexture == 0 {
                toneCurveTexture = generateTexture(minFilter: GL_LINEAR, magFilter: GL_LINEAR, wrapS: GL_CLAMP_TO_EDGE, wrapT: GL_CLAMP_TO_EDGE)
                toneCurveByteArray = Array(repeatElement(0, count: 256 * 4))
            } else {
                glActiveTexture(GLenum(GL_TEXTURE3))
                glBindTexture(GLenum(GL_TEXTURE_2D), toneCurveTexture)
            }
            
            if redCurve.count >= 256 && greenCurve.count >= 256 &&
                blueCurve.count >= 256 && rgbCompositeCurve.count >= 256 {
                for currentCurveIndex in 0 ..< 256 {
                    // BGRA for upload to texture
                    
                    let b = fmin(fmax(Float(currentCurveIndex) + blueCurve[currentCurveIndex], 0), 255)
                    
                    toneCurveByteArray[currentCurveIndex * 4] = GLubyte(fmin(fmax(b + rgbCompositeCurve[Int(b)], 0), 255))
                    let g = fmin(fmax(Float(currentCurveIndex) + greenCurve[currentCurveIndex], 0), 255)
                    
                    toneCurveByteArray[currentCurveIndex * 4 + 1] = GLubyte(fmin(fmax(g + rgbCompositeCurve[Int(g)], 0), 255))
                    let r = fmin(fmax(Float(currentCurveIndex) + redCurve[currentCurveIndex], 0), 255)
                    
                    toneCurveByteArray[currentCurveIndex * 4 + 2] = GLubyte(fmin(fmax(r + rgbCompositeCurve[Int(r)], 0), 255))
                    toneCurveByteArray[currentCurveIndex * 4 + 3] = 255
                }
                
                glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GLint(GL_RGBA), 256, 1, 0, GLenum(GL_BGRA), GLenum(GL_UNSIGNED_BYTE), toneCurveByteArray)
            }
        }
    }
}
