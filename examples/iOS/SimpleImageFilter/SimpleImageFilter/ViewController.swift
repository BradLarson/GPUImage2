import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture:PictureInput!
    var filter:SaturationAdjustment!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Filtering image for saving
        let testImage = UIImage(named:"WID-small.jpg")!
//        let toonFilter = SmoothToonFilter()
        let toonFilter = Luminance()
        
        let mask = CircleGenerator(size:Size(width:100, height:100.0))
        toonFilter.mask = mask
        mask.renderCircleOfRadius(0.2, center:Position.Center, circleColor:Color.Transparent, backgroundColor:Color.Black)
        
        let filteredImage = testImage.filterWithOperation(toonFilter)
        let pngImage = UIImagePNGRepresentation(filteredImage)!
        do {
            let documentsDir = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain:.UserDomainMask, appropriateForURL:nil, create:true)
            let fileURL = NSURL(string:"test.png", relativeToURL:documentsDir)!
            try pngImage.writeToURL(fileURL, options:.DataWritingAtomic)
        } catch {
            print("Couldn't write to file with error: \(error)")
        }
        
        // Filtering image for display
        picture = PictureInput(image:UIImage(named:"WID-small.jpg")!)
        filter = SaturationAdjustment()
        picture --> filter --> renderView
        picture.processImage()
    }
}

