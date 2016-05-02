import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!
    
    var movie:MovieInput!
    var filter:Pixellate!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bundleURL = NSBundle.mainBundle().resourceURL!
        let movieURL = NSURL(string:"sample_iPod.m4v", relativeToURL:bundleURL)!
        
        do {
            movie = try MovieInput(url:movieURL, playAtActualSpeed:true)
            filter = Pixellate()
            movie --> filter --> renderView
            movie.runBenchmark = true
            movie.start()
        } catch {
            print("Couldn't process movie with error: \(error)")
        }

//            let documentsDir = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain:.UserDomainMask, appropriateForURL:nil, create:true)
//            let fileURL = NSURL(string:"test.png", relativeToURL:documentsDir)!
//            try pngImage.writeToURL(fileURL, options:.DataWritingAtomic)
    }
}

