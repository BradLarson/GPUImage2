import Cocoa
import GPUImage
import AVFoundation

let blendImageName = "Lambeau.jpg"

class FilterShowcaseWindowController: NSWindowController {

    @IBOutlet var filterView: RenderView!

    @IBOutlet weak var filterSlider: NSSlider!
    
    dynamic var currentSliderValue:Float = 0.5 {
        willSet(newSliderValue) {
            switch (currentFilterOperation!.sliderConfiguration) {
                case .Enabled: currentFilterOperation!.updateBasedOnSliderValue(newSliderValue)
                case .Disabled: break
            }
        }
    }
    
    var currentFilterOperation: FilterOperationInterface?
    var videoCamera:Camera!
    lazy var blendImage:PictureInput = {
        return PictureInput(imageName:blendImageName)
    }()
    var currentlySelectedRow = 1

    override func windowDidLoad() {
        super.windowDidLoad()

        do {
            videoCamera = try Camera(sessionPreset:AVCaptureSessionPreset1280x720)
            videoCamera.runBenchmark = true
        } catch {
            fatalError("Couldn't initialize camera with error: \(error)")
        }
        self.changeSelectedRow(0)
    }
    
    func changeSelectedRow(row:Int) {
        guard (currentlySelectedRow != row) else { return }
        currentlySelectedRow = row
        
        // Clean up everything from the previous filter selection first
        videoCamera.stopCapture()
        videoCamera.removeAllTargets()
        currentFilterOperation?.filter.removeAllTargets()
        currentFilterOperation?.secondInput?.removeAllTargets()
        
        currentFilterOperation = filterOperations[row]
        switch currentFilterOperation!.filterOperationType {
            case .SingleInput:
                videoCamera.addTarget((currentFilterOperation!.filter))
                currentFilterOperation!.filter.addTarget(filterView!)
            case .Blend:
                blendImage.removeAllTargets()
                videoCamera.addTarget((currentFilterOperation!.filter))
                self.blendImage.addTarget((currentFilterOperation!.filter))
                currentFilterOperation!.filter.addTarget(filterView!)
                self.blendImage.processImage()
            case let .Custom(filterSetupFunction:setupFunction):
                currentFilterOperation!.configureCustomFilter(setupFunction(camera:videoCamera!, filter:currentFilterOperation!.filter, outputView:filterView!))
        }
        
        switch currentFilterOperation!.sliderConfiguration {
            case .Disabled:
                filterSlider.enabled = false
                //                case let .Enabled(minimumValue, initialValue, maximumValue, filterSliderCallback):
            case let .Enabled(minimumValue, maximumValue, initialValue):
                filterSlider.minValue = Double(minimumValue)
                filterSlider.maxValue = Double(maximumValue)
                filterSlider.enabled = true
                currentSliderValue = initialValue
        }
        
        videoCamera.startCapture()
    }

// MARK: -
// MARK: Table view delegate and datasource methods
    
    func numberOfRowsInTableView(aTableView:NSTableView!) -> Int {
        return filterOperations.count
    }
    
    func tableView(aTableView:NSTableView!, objectValueForTableColumn aTableColumn:NSTableColumn!, row rowIndex:Int) -> AnyObject! {
        let filterInList:FilterOperationInterface = filterOperations[rowIndex]
        return filterInList.listName
    }
    
    func tableViewSelectionDidChange(aNotification: NSNotification!) {
        if let currentTableView = aNotification.object as? NSTableView {
            let rowIndex = currentTableView.selectedRow
            self.changeSelectedRow(rowIndex)
        }
    }
}