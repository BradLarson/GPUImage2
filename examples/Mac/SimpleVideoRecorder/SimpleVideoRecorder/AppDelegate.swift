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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            camera = try Camera(sessionPreset:.vga640x480)
            filter = SmoothToonFilter()
            
            camera --> filter --> renderView
            camera.runBenchmark = true
            camera.startCapture()
        } catch {
            fatalError("Couldn't initialize pipeline, error: \(error)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        camera.stopCapture()
    }
    
    @IBAction func record(_ sender: AnyObject) {
        if (!isRecording) {
            let movieSavingDialog = NSSavePanel()
            movieSavingDialog.allowedFileTypes = ["mp4"]
            let okayButton = movieSavingDialog.runModal()
            
            if okayButton == NSApplication.ModalResponse.OK {
                do {
                    self.isRecording = true
//                    movieOutput = try MovieOutput(URL:movieSavingDialog.url!, size:Size(width:1280, height:720), liveVideo:true)
                    movieOutput = try MovieOutput(URL:movieSavingDialog.url!, size:Size(width:640, height:480), liveVideo:true)
//                    camera.audioEncodingTarget = movieOutput
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
                DispatchQueue.main.async {
                    (sender as! NSButton).title = "Record"
                }
//                self.camera.audioEncodingTarget = nil
                self.movieOutput = nil
            }
        }
    }

}

