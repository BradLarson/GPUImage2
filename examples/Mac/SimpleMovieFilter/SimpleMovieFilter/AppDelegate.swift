import Cocoa
import GPUImage

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var renderView: RenderView!
    
    var movie:MovieInput!
    var filter:Pixellate!
    
    @objc dynamic var filterValue = 0.05 {
        didSet {
            filter.fractionalWidthOfAPixel = GLfloat(filterValue)
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let bundleURL = Bundle.main.resourceURL!
        let movieURL = URL(string:"sample_iPod.m4v", relativeTo:bundleURL)!

        do {
            movie = try MovieInput(url:movieURL, playAtActualSpeed:true)
            filter = Pixellate()
            movie --> filter --> renderView
            movie.runBenchmark = true
            movie.start()
        } catch {
            print("Couldn't process movie with error: \(error)")
        }
    }
}

