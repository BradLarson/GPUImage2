import UIKit
import GPUImage
import AVFoundation

let blendImageName = "WID-small.jpg"

class FilterDisplayViewController: UIViewController, UISplitViewControllerDelegate {

    @IBOutlet var filterSlider: UISlider?
    @IBOutlet var filterView: RenderView?
    
    let videoCamera:Camera?
    var blendImage:PictureInput?

    required init(coder aDecoder: NSCoder)
    {
        do {
            videoCamera = try Camera(sessionPreset:AVCaptureSessionPreset640x480, location:.BackFacing)
            videoCamera!.runBenchmark = true
        } catch {
            videoCamera = nil
            print("Couldn't initialize camera with error: \(error)")
        }

        super.init(coder: aDecoder)!
    }
    
    var filterOperation: FilterOperationInterface?
    
    func configureView() {
        guard let videoCamera = videoCamera else {
            let errorAlertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: "Couldn't initialize camera", preferredStyle: .Alert)
            errorAlertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .Default, handler: nil))
            self.presentViewController(errorAlertController, animated: true, completion: nil)
            return
        }
        if let currentFilterConfiguration = self.filterOperation {
            self.title = currentFilterConfiguration.titleName
            
            // Configure the filter chain, ending with the view
            if let view = self.filterView {
                switch currentFilterConfiguration.filterOperationType {
                case .SingleInput:
                    videoCamera.addTarget(currentFilterConfiguration.filter)
                    currentFilterConfiguration.filter.addTarget(view)
                case .Blend:
                    videoCamera.addTarget(currentFilterConfiguration.filter)
                    self.blendImage = PictureInput(imageName:blendImageName)
                    self.blendImage?.addTarget(currentFilterConfiguration.filter)
                    self.blendImage?.processImage()
                    currentFilterConfiguration.filter.addTarget(view)
                case let .Custom(filterSetupFunction:setupFunction):
                    currentFilterConfiguration.configureCustomFilter(setupFunction(camera:videoCamera, filter:currentFilterConfiguration.filter, outputView:view))
                }
                
                videoCamera.startCapture()
            }

            // Hide or display the slider, based on whether the filter needs it
            if let slider = self.filterSlider {
                switch currentFilterConfiguration.sliderConfiguration {
                case .Disabled:
                    slider.hidden = true
//                case let .Enabled(minimumValue, initialValue, maximumValue, filterSliderCallback):
                case let .Enabled(minimumValue, maximumValue, initialValue):
                    slider.minimumValue = minimumValue
                    slider.maximumValue = maximumValue
                    slider.value = initialValue
                    slider.hidden = false
                    self.updateSliderValue()
                }
            }
            
        }
    }
    
    @IBAction func updateSliderValue() {
        if let currentFilterConfiguration = self.filterOperation {
            switch (currentFilterConfiguration.sliderConfiguration) {
                case .Enabled(_, _, _): currentFilterConfiguration.updateBasedOnSliderValue(Float(self.filterSlider!.value))
                case .Disabled: break
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }

    override func viewWillDisappear(animated: Bool) {
        if let videoCamera = videoCamera {
            videoCamera.stopCapture()
            videoCamera.removeAllTargets()
            blendImage?.removeAllTargets()
        }
        
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

