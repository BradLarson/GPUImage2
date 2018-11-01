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
            camera = try Camera(sessionPreset:.vga640x480)
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
    
    @IBAction func capture(_ sender: AnyObject) {
        if (!isRecording) {
            do {
                self.isRecording = true
                let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
                let fileURL = URL(string:"test.mp4", relativeTo:documentsDir)!
                do {
                    try FileManager.default.removeItem(at:fileURL)
                } catch {
                }
                
                movieOutput = try MovieOutput(URL:fileURL, size:Size(width:480, height:640), liveVideo:true)
                camera.audioEncodingTarget = movieOutput
                filter --> movieOutput!
                movieOutput!.startRecording()
                DispatchQueue.main.async {
                    // Label not updating on the main thread, for some reason, so dispatching slightly after this
                    (sender as! UIButton).titleLabel!.text = "Stop"
                }
            } catch {
                fatalError("Couldn't initialize movie, error: \(error)")
            }
        } else {
            movieOutput?.finishRecording{
                self.isRecording = false
                DispatchQueue.main.async {
                    (sender as! UIButton).titleLabel!.text = "Record"
                }
                self.camera.audioEncodingTarget = nil
                self.movieOutput = nil
            }
        }
    }
}
