import Cocoa
import GPUImage

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var renderView: RenderView!

    var image:PictureInput!
    var filter:SaturationAdjustment!

    @objc dynamic var filterValue = 1.0 {
        didSet {
            filter.saturation = GLfloat(filterValue)
            image.processImage()
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let inputImage = NSImage(named:NSImage.Name(rawValue: "Lambeau.jpg"))!
        image = PictureInput(image:inputImage)
        
        filter = SaturationAdjustment()
        
        image --> filter --> renderView
        image.processImage()
    }
}

