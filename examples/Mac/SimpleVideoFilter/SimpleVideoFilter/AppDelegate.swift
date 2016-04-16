import Cocoa
import GPUImage
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var renderView: RenderView!
    
    var camera:Camera!
    var filter:Pixellate!

    dynamic var filterSetting:Float = 0.01 {
        didSet {
            filter.fractionalWidthOfAPixel = filterSetting
        }
    }
    
    @IBAction func capture(sender: AnyObject) {
        let imageSavingDialog = NSSavePanel()
        imageSavingDialog.allowedFileTypes = ["png"]
        let okayButton = imageSavingDialog.runModal()
        
        if okayButton == NSModalResponseOK {
            filter.saveNextFrameToURL(imageSavingDialog.URL!, format:.PNG)
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        do {
            camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
            filter = Pixellate()

            camera --> filter --> renderView
            camera.startCapture()
        } catch {
            fatalError("Couldn't initialize pipeline, error: \(error)")
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        camera.stopCapture()
    }
}