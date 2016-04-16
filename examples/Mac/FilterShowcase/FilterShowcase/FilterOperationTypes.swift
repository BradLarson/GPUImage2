import Foundation
import GPUImage

enum FilterSliderSetting {
    case Disabled
    case Enabled(minimumValue:Float, maximumValue:Float, initialValue:Float)
}

typealias FilterSetupFunction = (camera:Camera, filter:ImageProcessingOperation, outputView:RenderView) -> ImageSource?

enum FilterOperationType {
    case SingleInput
    case Blend
    case Custom(filterSetupFunction:FilterSetupFunction)
}

protocol FilterOperationInterface {
    var filter: ImageProcessingOperation { get }
    var secondInput:ImageSource? { get }
    var listName: String { get }
    var titleName: String { get }
    var sliderConfiguration: FilterSliderSetting  { get }
    var filterOperationType: FilterOperationType  { get }

    func configureCustomFilter(secondInput:ImageSource?)
    func updateBasedOnSliderValue(sliderValue:Float)
}

class FilterOperation<FilterClass: ImageProcessingOperation>: FilterOperationInterface {
    lazy var internalFilter:FilterClass = {
        return self.filterCreationFunction()
    }()
    let filterCreationFunction:() -> FilterClass
    var secondInput:ImageSource?
    let listName:String
    let titleName:String
    let sliderConfiguration:FilterSliderSetting
    let filterOperationType:FilterOperationType
    let sliderUpdateCallback: ((filter:FilterClass, sliderValue:Float) -> ())?
    init(filter:() -> FilterClass, listName: String, titleName: String, sliderConfiguration: FilterSliderSetting, sliderUpdateCallback:((filter:FilterClass, sliderValue:Float) -> ())?, filterOperationType: FilterOperationType) {
        self.listName = listName
        self.titleName = titleName
        self.sliderConfiguration = sliderConfiguration
        self.filterOperationType = filterOperationType
        self.sliderUpdateCallback = sliderUpdateCallback
        self.filterCreationFunction = filter
    }
    
    var filter: ImageProcessingOperation {
        return internalFilter
    }

    func configureCustomFilter(secondInput:ImageSource?) {
        self.secondInput = secondInput
    }

    func updateBasedOnSliderValue(sliderValue:Float) {
        sliderUpdateCallback?(filter:internalFilter, sliderValue:sliderValue)
    }
}