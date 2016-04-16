import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture:PictureInput!
    var filter:SaturationAdjustment!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        picture = PictureInput(image:UIImage(named:"WID-small.jpg")!)
        filter = SaturationAdjustment()
        picture --> filter --> renderView
        picture.processImage()
    }
}

