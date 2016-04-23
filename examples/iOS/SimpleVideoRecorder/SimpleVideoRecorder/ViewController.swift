import UIKit
import GPUImage
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var renderView: RenderView!
    var camera:Camera!
    var filter:SaturationAdjustment!
    var isRecording = false
    var movieOutput:MovieOutput? = nil

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
        if (!isRecording) {
            do {
                self.isRecording = true
                let documentsDir = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain:.UserDomainMask, appropriateForURL:nil, create:true)
                let fileURL = NSURL(string:"test.mp4", relativeToURL:documentsDir)!
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(fileURL)
                } catch {
                }
                
                movieOutput = try MovieOutput(URL:fileURL, size:Size(width:480, height:640), liveVideo:true)
                filter --> movieOutput!
                movieOutput!.startRecording()
                (sender as! UIButton).titleLabel?.text = "Stop"
            } catch {
                fatalError("Couldn't initialize movie, error: \(error)")
            }
        } else {
            movieOutput?.finishRecording{
                self.isRecording = false
                dispatch_async(dispatch_get_main_queue()) {
                    (sender as! UIButton).titleLabel?.text = "Record"
                }
                self.movieOutput = nil
            }
        }
    }
}