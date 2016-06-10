import UIKit
import CoreImage
import GPUImage
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var renderView: RenderView!
    @IBOutlet weak var faceDetectSwitch: UISwitch!

    let fbSize = Size(width: 640, height: 480)
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])
    var shouldDetectFaces = true
    lazy var lineGenerator: LineGenerator = {
        let gen = LineGenerator(size: self.fbSize)
        gen.lineWidth = 5
        return gen
    }()
    let saturationFilter = SaturationAdjustment()
    let blendFilter = AlphaBlend()
    var camera:Camera!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
            camera.runBenchmark = true
            camera.delegate = self
            camera --> saturationFilter --> blendFilter --> renderView
            lineGenerator --> blendFilter
            shouldDetectFaces = faceDetectSwitch.on
            camera.startCapture()
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    @IBAction func didSwitch(sender: UISwitch) {
        shouldDetectFaces = sender.on
    }

    @IBAction func capture(sender: AnyObject) {
        print("Capture")
        do {
            let documentsDir = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain:.UserDomainMask, appropriateForURL:nil, create:true)
            saturationFilter.saveNextFrameToURL(NSURL(string:"TestImage.png", relativeToURL:documentsDir)!, format:.PNG)
        } catch {
            print("Couldn't save image: \(error)")
        }
    }
}

extension ViewController: CameraDelegate {
    func didCaptureBuffer(sampleBuffer: CMSampleBuffer) {
        guard shouldDetectFaces else {
            lineGenerator.renderLines([]) // clear
            return
        }
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))!
            let img = CIImage(CVPixelBuffer: pixelBuffer, options: attachments as? [String: AnyObject])
            var lines = [Line]()
            for feature in faceDetector.featuresInImage(img, options: [CIDetectorImageOrientation: 6]) {
                if feature is CIFaceFeature {
                    lines = lines + faceLines(feature.bounds)
                }
            }
            lineGenerator.renderLines(lines)
        }
    }

    func faceLines(bounds: CGRect) -> [Line] {
        // convert from CoreImage to GL coords
        let flip = CGAffineTransformMakeScale(1, -1)
        let rotate = CGAffineTransformRotate(flip, CGFloat(-M_PI_2))
        let translate = CGAffineTransformTranslate(rotate, -1, -1)
        let xform = CGAffineTransformScale(translate, CGFloat(2/fbSize.width), CGFloat(2/fbSize.height))
        let glRect = CGRectApplyAffineTransform(bounds, xform)

        let x = Float(glRect.origin.x)
        let y = Float(glRect.origin.y)
        let width = Float(glRect.size.width)
        let height = Float(glRect.size.height)

        let tl = Position(x, y)
        let tr = Position(x + width, y)
        let bl = Position(x, y + height)
        let br = Position(x + width, y + height)

        return [.Segment(p1:tl, p2:tr),   // top
                .Segment(p1:tr, p2:br),   // right
                .Segment(p1:br, p2:bl),   // bottom
                .Segment(p1:bl, p2:tl)]   // left
    }
}
