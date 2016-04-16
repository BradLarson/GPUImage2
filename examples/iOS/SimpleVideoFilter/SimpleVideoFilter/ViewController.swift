import UIKit
import GPUImage
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var renderView: RenderView!
    var camera:Camera!
    var filter:SaturationAdjustment!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
            camera.runBenchmark = true
            filter = SaturationAdjustment()
            camera --> filter --> renderView
            camera.startCapture()
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    @IBAction func capture(sender: AnyObject) {
        print("Capture")
        do {
            let documentsDir = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain:.UserDomainMask, appropriateForURL:nil, create:true)
            filter.saveNextFrameToURL(NSURL(string:"TestImage.png", relativeToURL:documentsDir)!, format:.PNG)
        } catch {
            print("Couldn't save image: \(error)")
        }
    }
}

