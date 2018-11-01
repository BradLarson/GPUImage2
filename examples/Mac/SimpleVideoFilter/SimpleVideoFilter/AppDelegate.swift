import Cocoa
import GPUImage
import AVFoundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var renderView: RenderView!
    
    var camera:Camera!
    var filter:Pixellate!

    @objc dynamic var filterSetting:Float = 0.01 {
        didSet {
            filter.fractionalWidthOfAPixel = filterSetting
        }
    }
    
    @IBAction func capture(_ sender: AnyObject) {
        let imageSavingDialog = NSSavePanel()
        imageSavingDialog.allowedFileTypes = ["png"]
        let okayButton = imageSavingDialog.runModal()
        
        if okayButton == NSApplication.ModalResponse.OK {
            filter.saveNextFrameToURL(imageSavingDialog.url!, format:.png)
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            camera = try Camera(sessionPreset:.vga640x480)
            filter = Pixellate()

            camera --> filter --> renderView
            camera.startCapture()
        } catch {
            fatalError("Couldn't initialize pipeline, error: \(error)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        camera.stopCapture()
    }
}
