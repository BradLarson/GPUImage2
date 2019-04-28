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
        let toonFilter = SmoothToonFilter()
        
        let filteredImage:UIImage
        do {
            filteredImage = try testImage.filterWithOperation(toonFilter)
        } catch {
            print("Couldn't filter image with error: \(error)")
            return
        }
        
        let pngImage = UIImagePNGRepresentation(filteredImage)!
        do {
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            let fileURL = URL(string:"test.png", relativeTo:documentsDir)!
            try pngImage.write(to:fileURL, options:.atomic)
        } catch {
            print("Couldn't write to file with error: \(error)")
        }
        
        
        // Filtering image for display
        do {
            picture = try PictureInput(image:UIImage(named:"WID-small.jpg")!)
        } catch {
            print("Couldn't create PictureInput with error: \(error)")
            return
        }
        filter = SaturationAdjustment()
        picture --> filter --> renderView
        picture.processImage()
    }
}

