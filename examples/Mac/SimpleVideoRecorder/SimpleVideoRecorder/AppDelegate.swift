import Cocoa
import GPUImage
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window:NSWindow!
    @IBOutlet var renderView:RenderView!

    var camera:Camera!
    var filter:SmoothToonFilter!
    var movieOutput:MovieOutput?
    var isRecording = false

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        do {
            camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
            filter = SmoothToonFilter()
            
            camera --> filter --> renderView
            camera.startCapture()
        } catch {
            fatalError("Couldn't initialize pipeline, error: \(error)")
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        camera.stopCapture()
    }
    
    @IBAction func record(sender: AnyObject) {
        if (!isRecording) {
            let movieSavingDialog = NSSavePanel()
            movieSavingDialog.allowedFileTypes = ["mp4"]
            let okayButton = movieSavingDialog.runModal()
            
            if okayButton == NSModalResponseOK {
                do {
                    self.isRecording = true
                    movieOutput = try MovieOutput(URL:movieSavingDialog.URL!, size:Size(width:1280, height:720), liveVideo:true)
                    filter --> movieOutput!
                    movieOutput!.startRecording()
                    (sender as! NSButton).title = "Stop"
                } catch {
                    fatalError("Couldn't initialize movie, error: \(error)")
                }
            }
        } else {
            movieOutput?.finishRecording{
                self.isRecording = false
                dispatch_async(dispatch_get_main_queue()) {
                    (sender as! NSButton).title = "Record"
                }
                self.movieOutput = nil
            }
        }
    }

}

