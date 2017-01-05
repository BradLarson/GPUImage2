import Foundation
import GPUImage

enum FilterSliderSetting {
    case disabled
    case enabled(minimumValue:Float, maximumValue:Float, initialValue:Float)
}

#if os(iOS)
typealias FilterSetupFunction = (_ camera:GPUImageVideoCamera, _ outputView:GPUImageView) -> (filter:GPUImageOutput, secondOutput:GPUImageOutput?)
#else
typealias FilterSetupFunction = (_ camera:GPUImageAVCamera, _ outputView:GPUImageView) -> (filter:GPUImageOutput, secondOutput:GPUImageOutput?)
#endif

enum FilterOperationType {
    case singleInput
    case blend
    case custom(filterSetupFunction:FilterSetupFunction)
}

protocol FilterOperationInterface {
    var filter: GPUImageOutput { get }
    var listName: String { get }
    var titleName: String { get }
    var sliderConfiguration: FilterSliderSetting  { get }
    var filterOperationType: FilterOperationType  { get }

    func configureCustomFilter(input:(filter:GPUImageOutput, secondInput:GPUImageOutput?))
    func updateBasedOnSliderValue(sliderValue:CGFloat)
}

class FilterOperation<FilterClass: GPUImageOutput>: FilterOperationInterface where FilterClass: GPUImageInput {
    var internalFilter: FilterClass?
    var secondInput: GPUImageOutput?
    let listName: String
    let titleName: String
    let sliderConfiguration: FilterSliderSetting
    let filterOperationType: FilterOperationType
    let sliderUpdateCallback: ((_ filter:FilterClass, _ sliderValue:CGFloat) -> ())?
    init(listName: String, titleName: String, sliderConfiguration: FilterSliderSetting, sliderUpdateCallback:((_ filter:FilterClass, _ sliderValue:CGFloat) -> ())?, filterOperationType: FilterOperationType) {
        self.listName = listName
        self.titleName = titleName
        self.sliderConfiguration = sliderConfiguration
        self.filterOperationType = filterOperationType
        self.sliderUpdateCallback = sliderUpdateCallback
        switch (filterOperationType) {
            case .custom:
                break
            default:
                self.internalFilter = FilterClass()
        }
    }
    
    var filter: GPUImageOutput {
        return internalFilter!
    }

    func configureCustomFilter(input:(filter:GPUImageOutput, secondInput:GPUImageOutput?)) {
        self.internalFilter = (input.filter as! FilterClass)
        self.secondInput = input.secondInput
    }

    func updateBasedOnSliderValue(sliderValue:CGFloat) {
        if let updateFunction = sliderUpdateCallback
        {
            updateFunction(filter:internalFilter!, sliderValue:sliderValue)
        }
    }
}
