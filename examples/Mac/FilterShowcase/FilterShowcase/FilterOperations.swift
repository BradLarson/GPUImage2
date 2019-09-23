import GPUImage
import QuartzCore

let filterOperations: Array<FilterOperationInterface> = [
    FilterOperation (
        filter:{SaturationAdjustment()},
        listName:"Saturation",
        titleName:"Saturation",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:2.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.saturation = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{ContrastAdjustment()},
        listName:"Contrast",
        titleName:"Contrast",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:4.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.contrast = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{BrightnessAdjustment()},
        listName:"Brightness",
        titleName:"Brightness",
        sliderConfiguration:.enabled(minimumValue:-1.0, maximumValue:1.0, initialValue:0.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.brightness = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{LevelsAdjustment()},
        listName:"Levels",
        titleName:"Levels",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.minimum = Color(red:Float(sliderValue), green:Float(sliderValue), blue:Float(sliderValue))
            filter.middle = Color(red:1.0, green:1.0, blue:1.0)
            filter.maximum = Color(red:1.0, green:1.0, blue:1.0)
            filter.minOutput = Color(red:0.0, green:0.0, blue:0.0)
            filter.maxOutput = Color(red:1.0, green:1.0, blue:1.0)
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{ExposureAdjustment()},
        listName:"Exposure",
        titleName:"Exposure",
        sliderConfiguration:.enabled(minimumValue:-4.0, maximumValue:4.0, initialValue:0.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.exposure = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{RGBAdjustment()},
        listName:"RGB",
        titleName:"RGB",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:2.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.green = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{HueAdjustment()},
        listName:"Hue",
        titleName:"Hue",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:360.0, initialValue:90.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.hue = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{WhiteBalance()},
        listName:"White balance",
        titleName:"White Balance",
        sliderConfiguration:.enabled(minimumValue:2500.0, maximumValue:7500.0, initialValue:5000.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.temperature = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{MonochromeFilter()},
        listName:"Monochrome",
        titleName:"Monochrome",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.intensity = sliderValue
        },
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! MonochromeFilter
            camera --> castFilter --> outputView
            castFilter.color = Color(red:0.0, green:0.0, blue:1.0, alpha:1.0)
            return nil
        })
    ),
    FilterOperation(
        filter:{FalseColor()},
        listName:"False color",
        titleName:"False Color",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Sharpen()},
        listName:"Sharpen",
        titleName:"Sharpen",
        sliderConfiguration:.enabled(minimumValue:-1.0, maximumValue:4.0, initialValue:0.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.sharpness = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{UnsharpMask()},
        listName:"Unsharp mask",
        titleName:"Unsharp Mask",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:5.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.intensity = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{TransformOperation()},
        listName:"Transform (2-D)",
        titleName:"Transform (2-D)",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:6.28, initialValue:0.75),
        sliderUpdateCallback:{(filter, sliderValue) in
            filter.transform = Matrix4x4(CGAffineTransform(rotationAngle:CGFloat(sliderValue)))
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{TransformOperation()},
        listName:"Transform (3-D)",
        titleName:"Transform (3-D)",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:6.28, initialValue:0.75),
        sliderUpdateCallback:{(filter, sliderValue) in
            var perspectiveTransform = CATransform3DIdentity
            perspectiveTransform.m34 = 0.4
            perspectiveTransform.m33 = 0.4
            perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75)
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, CGFloat(sliderValue), 0.0, 1.0, 0.0)
            filter.transform = Matrix4x4(perspectiveTransform)
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Crop()},
        listName:"Crop",
        titleName:"Crop",
        sliderConfiguration:.enabled(minimumValue:240.0, maximumValue:480.0, initialValue:240.0),
        sliderUpdateCallback:{(filter, sliderValue) in
            filter.cropSizeInPixels = Size(width:480.0, height:sliderValue)
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Luminance()},
        listName:"Masking",
        titleName:"Mask Example",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! Luminance
            let maskImage = try! PictureInput(imageName:"Mask.png")
            castFilter.drawUnmodifiedImageOutsideOfMask = false
            castFilter.mask = maskImage
            maskImage.processImage()
            camera --> castFilter --> outputView
            return nil
        })
    ),
    FilterOperation(
        filter:{GammaAdjustment()},
        listName:"Gamma",
        titleName:"Gamma",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:3.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.gamma = sliderValue
        },
        filterOperationType:.singleInput
    ),
// TODO : Tone curve
    FilterOperation(
        filter:{HighlightsAndShadows()},
        listName:"Highlights and shadows",
        titleName:"Highlights and Shadows",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.highlights = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Haze()},
        listName:"Haze / UV",
        titleName:"Haze / UV",
        sliderConfiguration:.enabled(minimumValue:-0.2, maximumValue:0.2, initialValue:0.2),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.distance = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{SepiaToneFilter()},
        listName:"Sepia tone",
        titleName:"Sepia Tone",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.intensity = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{AmatorkaFilter()},
        listName:"Amatorka (Lookup)",
        titleName:"Amatorka (Lookup)",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{MissEtikateFilter()},
        listName:"Miss Etikate (Lookup)",
        titleName:"Miss Etikate (Lookup)",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{SoftElegance()},
        listName:"Soft elegance (Lookup)",
        titleName:"Soft Elegance (Lookup)",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{ColorInversion()},
        listName:"Color invert",
        titleName:"Color Invert",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Solarize()},
        listName:"Solarize",
        titleName:"Solarize",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.5),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.threshold = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Vibrance()},
        listName:"Vibrance",
        titleName:"Vibrance",
        sliderConfiguration:.enabled(minimumValue:-1.2, maximumValue:1.2, initialValue:0.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.vibrance = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{HighlightAndShadowTint()},
        listName:"Highlight and shadow tint",
        titleName:"Highlight / Shadow Tint",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.shadowTintIntensity = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation (
        filter:{Luminance()},
        listName:"Luminance",
        titleName:"Luminance",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Histogram(type:.rgb)},
        listName:"Histogram",
        titleName:"Histogram",
        sliderConfiguration:.enabled(minimumValue:4.0, maximumValue:32.0, initialValue:16.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.downsamplingFactor = UInt(roundf(sliderValue))
        },
        filterOperationType:.custom(filterSetupFunction: {(camera, filter, outputView) in
            let castFilter = filter as! Histogram
            let histogramGraph = HistogramDisplay()
            histogramGraph.overriddenOutputSize = Size(width:256.0, height:330.0)
            let blendFilter = AlphaBlend()
            blendFilter.mix = 0.75
            camera --> blendFilter
            camera --> castFilter --> histogramGraph --> blendFilter --> outputView
            
            return blendFilter
        })
    ),
    FilterOperation (
        filter:{HistogramEqualization(type:.rgb)},
        listName:"Histogram equalization",
        titleName:"Histogram Equalization",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{AverageColorExtractor()},
        listName:"Average color",
        titleName:"Average Color",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! AverageColorExtractor
            let colorGenerator = SolidColorGenerator(size:outputView.sizeInPixels)
            
            castFilter.extractedColorCallback = {color in
                colorGenerator.renderColor(color)
            }
            camera --> castFilter
            colorGenerator --> outputView
            return colorGenerator
        })
    ),
    FilterOperation(
        filter:{AverageLuminanceExtractor()},
        listName:"Average luminosity",
        titleName:"Average Luminosity",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! AverageLuminanceExtractor
            let colorGenerator = SolidColorGenerator(size:outputView.sizeInPixels)
            
            castFilter.extractedLuminanceCallback = {luminosity in
                colorGenerator.renderColor(Color(red:luminosity, green:luminosity, blue:luminosity))
            }
            
            camera --> castFilter
            colorGenerator --> outputView
            return colorGenerator
        })
    ),
    FilterOperation(
        filter:{LuminanceThreshold()},
        listName:"Luminance threshold",
        titleName:"Luminance Threshold",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.5),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.threshold = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{AdaptiveThreshold()},
        listName:"Adaptive threshold",
        titleName:"Adaptive Threshold",
        sliderConfiguration:.enabled(minimumValue:1.0, maximumValue:20.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.blurRadiusInPixels = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{AverageLuminanceThreshold()},
        listName:"Average luminance threshold",
        titleName:"Avg. Lum. Threshold",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:2.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.thresholdMultiplier = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Pixellate()},
        listName:"Pixellate",
        titleName:"Pixellate",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:0.3, initialValue:0.05),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.fractionalWidthOfAPixel = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{PolarPixellate()},
        listName:"Polar pixellate",
        titleName:"Polar Pixellate",
        sliderConfiguration:.enabled(minimumValue:-0.1, maximumValue:0.1, initialValue:0.05),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.pixelSize = Size(width:sliderValue, height:sliderValue)
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Pixellate()},
        listName:"Masked Pixellate",
        titleName:"Masked Pixellate",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! Pixellate
            castFilter.fractionalWidthOfAPixel = 0.05
            // TODO: Find a way to not hardcode these values
#if os(iOS)
            let circleGenerator = CircleGenerator(size:Size(width:480, height:640))
#else
            let circleGenerator = CircleGenerator(size:Size(width:1280, height:720))
#endif
            castFilter.mask = circleGenerator
            circleGenerator.renderCircleOfRadius(0.25, center:Position.center, circleColor:Color.white, backgroundColor:Color.transparent)
            camera --> castFilter --> outputView
            return nil
        })
    ),
    FilterOperation(
        filter:{PolkaDot()},
        listName:"Polka dot",
        titleName:"Polka Dot",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:0.3, initialValue:0.05),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.fractionalWidthOfAPixel = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Halftone()},
        listName:"Halftone",
        titleName:"Halftone",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:0.05, initialValue:0.01),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.fractionalWidthOfAPixel = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Crosshatch()},
        listName:"Crosshatch",
        titleName:"Crosshatch",
        sliderConfiguration:.enabled(minimumValue:0.01, maximumValue:0.06, initialValue:0.03),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.crossHatchSpacing = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{SobelEdgeDetection()},
        listName:"Sobel edge detection",
        titleName:"Sobel Edge Detection",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.25),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.edgeStrength = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{PrewittEdgeDetection()},
        listName:"Prewitt edge detection",
        titleName:"Prewitt Edge Detection",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.edgeStrength = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{CannyEdgeDetection()},
        listName:"Canny edge detection",
        titleName:"Canny Edge Detection",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:4.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.blurRadiusInPixels = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{ThresholdSobelEdgeDetection()},
        listName:"Threshold edge detection",
        titleName:"Threshold Edge Detection",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.25),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.threshold = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{HarrisCornerDetector()},
        listName:"Harris corner detector",
        titleName:"Harris Corner Detector",
        sliderConfiguration:.enabled(minimumValue:0.01, maximumValue:0.70, initialValue:0.20),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.threshold = sliderValue
        },
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! HarrisCornerDetector
            // TODO: Get this more dynamically sized
#if os(iOS)
            let crosshairGenerator = CrosshairGenerator(size:Size(width:480, height:640))
#else
            let crosshairGenerator = CrosshairGenerator(size:Size(width:1280, height:720))
#endif
            crosshairGenerator.crosshairWidth = 15.0
            
            castFilter.cornersDetectedCallback = { corners in
                crosshairGenerator.renderCrosshairs(corners)
            }

            camera --> castFilter
            
            let blendFilter = AlphaBlend()
            camera --> blendFilter --> outputView
            crosshairGenerator --> blendFilter
        
            return blendFilter
        })
    ),
    FilterOperation(
        filter:{NobleCornerDetector()},
        listName:"Noble corner detector",
        titleName:"Noble Corner Detector",
        sliderConfiguration:.enabled(minimumValue:0.01, maximumValue:0.70, initialValue:0.20),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.threshold = sliderValue
        },
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! NobleCornerDetector
            // TODO: Get this more dynamically sized
#if os(iOS)
                let crosshairGenerator = CrosshairGenerator(size:Size(width:480, height:640))
#else
                let crosshairGenerator = CrosshairGenerator(size:Size(width:1280, height:720))
#endif
            crosshairGenerator.crosshairWidth = 15.0
            
            castFilter.cornersDetectedCallback = { corners in
                crosshairGenerator.renderCrosshairs(corners)
            }
            
            camera --> castFilter
            
            let blendFilter = AlphaBlend()
            camera --> blendFilter --> outputView
            crosshairGenerator --> blendFilter
            
            return blendFilter
        })
    ),
    FilterOperation(
        filter:{ShiTomasiFeatureDetector()},
        listName:"Shi-Tomasi feature detector",
        titleName:"Shi-Tomasi Feature Detector",
        sliderConfiguration:.enabled(minimumValue:0.01, maximumValue:0.70, initialValue:0.20),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.threshold = sliderValue
        },
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! ShiTomasiFeatureDetector
            // TODO: Get this more dynamically sized
#if os(iOS)
                let crosshairGenerator = CrosshairGenerator(size:Size(width:480, height:640))
#else
                let crosshairGenerator = CrosshairGenerator(size:Size(width:1280, height:720))
#endif
            crosshairGenerator.crosshairWidth = 15.0
            
            castFilter.cornersDetectedCallback = { corners in
                crosshairGenerator.renderCrosshairs(corners)
            }
            
            camera --> castFilter
            
            let blendFilter = AlphaBlend()
            camera --> blendFilter --> outputView
            crosshairGenerator --> blendFilter
            
            return blendFilter
        })
    ),
    // TODO: Hough transform line detector
    FilterOperation(
        filter:{ColourFASTFeatureDetection()},
        listName:"ColourFAST feature detection",
        titleName:"ColourFAST Features",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{LowPassFilter()},
        listName:"Low pass",
        titleName:"Low Pass",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.5),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.strength = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{HighPassFilter()},
        listName:"High pass",
        titleName:"High Pass",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.5),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.strength = sliderValue
        },
        filterOperationType:.singleInput
    ),
    // TODO: Motion detector

    FilterOperation(
        filter:{SketchFilter()},
        listName:"Sketch",
        titleName:"Sketch",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.5),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.edgeStrength = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{ThresholdSketchFilter()},
        listName:"Threshold Sketch",
        titleName:"Threshold Sketch",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.25),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.threshold = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{ToonFilter()},
        listName:"Toon",
        titleName:"Toon",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{SmoothToonFilter()},
        listName:"Smooth toon",
        titleName:"Smooth Toon",
        sliderConfiguration:.enabled(minimumValue:1.0, maximumValue:6.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.blurRadiusInPixels = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{TiltShift()},
        listName:"Tilt shift",
        titleName:"Tilt Shift",
        sliderConfiguration:.enabled(minimumValue:0.2, maximumValue:0.8, initialValue:0.5),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.topFocusLevel = sliderValue - 0.1
            filter.bottomFocusLevel = sliderValue + 0.1
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{CGAColorspaceFilter()},
        listName:"CGA colorspace",
        titleName:"CGA Colorspace",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Posterize()},
        listName:"Posterize",
        titleName:"Posterize",
        sliderConfiguration:.enabled(minimumValue:1.0, maximumValue:20.0, initialValue:10.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.colorLevels = roundf(sliderValue)
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Convolution3x3()},
        listName:"3x3 convolution",
        titleName:"3x3 convolution",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! Convolution3x3

            castFilter.convolutionKernel = Matrix3x3(rowMajorValues:[
                -1.0, 0.0, 1.0,
                -2.0, 0.0, 2.0,
                -1.0, 0.0, 1.0])
            
            camera --> castFilter --> outputView
            
            return nil
        })
    ),
    FilterOperation(
        filter:{EmbossFilter()},
        listName:"Emboss",
        titleName:"Emboss",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:5.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.intensity = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Laplacian()},
        listName:"Laplacian",
        titleName:"Laplacian",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{ChromaKeying()},
        listName:"Chroma key",
        titleName:"Chroma Key",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.00, initialValue:0.40),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.thresholdSensitivity = sliderValue
        },
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! ChromaKeying
            
            let blendFilter = AlphaBlend()
            blendFilter.mix = 1.0
            
            let inputImage = try! PictureInput(imageName:blendImageName)
            
            inputImage --> blendFilter
            camera --> castFilter --> blendFilter --> outputView
            inputImage.processImage()
            return blendFilter
        })
    ),
    FilterOperation(
        filter:{KuwaharaFilter()},
        listName:"Kuwahara",
        titleName:"Kuwahara",
        sliderConfiguration:.enabled(minimumValue:3.0, maximumValue:9.0, initialValue:3.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.radius = Int(roundf(sliderValue))
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{KuwaharaRadius3Filter()},
        listName:"Kuwahara (radius 3)",
        titleName:"Kuwahara (Radius 3)",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Vignette()},
        listName:"Vignette",
        titleName:"Vignette",
        sliderConfiguration:.enabled(minimumValue:0.5, maximumValue:0.9, initialValue:0.75),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.end = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{GaussianBlur()},
        listName:"Gaussian blur",
        titleName:"Gaussian Blur",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:40.0, initialValue:2.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.blurRadiusInPixels = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{BoxBlur()},
        listName:"Box blur",
        titleName:"Box Blur",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:40.0, initialValue:2.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.blurRadiusInPixels = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{MedianFilter()},
        listName:"Median",
        titleName:"Median",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{BilateralBlur()},
        listName:"Bilateral blur",
        titleName:"Bilateral Blur",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:10.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.distanceNormalizationFactor = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{MotionBlur()},
        listName:"Motion blur",
        titleName:"Motion Blur",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:180.0, initialValue:0.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.blurAngle = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{ZoomBlur()},
        listName:"Zoom blur",
        titleName:"Zoom Blur",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:2.5, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.blurSize = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation( // TODO: Make this only partially applied to the view
        filter:{iOSBlur()},
        listName:"iOS 7 blur",
        titleName:"iOS 7 Blur",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{SwirlDistortion()},
        listName:"Swirl",
        titleName:"Swirl",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:2.0, initialValue:1.0),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.angle = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{BulgeDistortion()},
        listName:"Bulge",
        titleName:"Bulge",
        sliderConfiguration:.enabled(minimumValue:-1.0, maximumValue:1.0, initialValue:0.5),
        sliderUpdateCallback: {(filter, sliderValue) in
            //            filter.scale = sliderValue
            filter.center = Position(0.5, sliderValue)
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{PinchDistortion()},
        listName:"Pinch",
        titleName:"Pinch",
        sliderConfiguration:.enabled(minimumValue:-2.0, maximumValue:2.0, initialValue:0.5),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.scale = sliderValue
        },
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{SphereRefraction()},
        listName:"Sphere refraction",
        titleName:"Sphere Refraction",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.15),
        sliderUpdateCallback:{(filter, sliderValue) in
            filter.radius = sliderValue
        },
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! SphereRefraction
            
            // Provide a blurred image for a cool-looking background
            let gaussianBlur = GaussianBlur()
            gaussianBlur.blurRadiusInPixels = 5.0
            
            let blendFilter = AlphaBlend()
            blendFilter.mix = 1.0
            
            camera --> gaussianBlur --> blendFilter --> outputView
            camera --> castFilter --> blendFilter
            
            return blendFilter
        })
    ),
    FilterOperation(
        filter:{GlassSphereRefraction()},
        listName:"Glass sphere",
        titleName:"Glass Sphere",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.15),
        sliderUpdateCallback:{(filter, sliderValue) in
            filter.radius = sliderValue
        },
        filterOperationType:.custom(filterSetupFunction:{(camera, filter, outputView) in
            let castFilter = filter as! GlassSphereRefraction
            
            // Provide a blurred image for a cool-looking background
            let gaussianBlur = GaussianBlur()
            gaussianBlur.blurRadiusInPixels = 5.0
            
            let blendFilter = AlphaBlend()
            blendFilter.mix = 1.0
            
            camera --> gaussianBlur --> blendFilter --> outputView
            camera --> castFilter --> blendFilter
            
            return blendFilter
        })
    ),
    FilterOperation (
        filter:{StretchDistortion()},
        listName:"Stretch",
        titleName:"Stretch",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Dilation()},
        listName:"Dilation",
        titleName:"Dilation",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{Erosion()},
        listName:"Erosion",
        titleName:"Erosion",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{OpeningFilter()},
        listName:"Opening",
        titleName:"Opening",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{ClosingFilter()},
        listName:"Closing",
        titleName:"Closing",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.singleInput
    ),
    // TODO: Perlin noise
    // TODO: JFAVoronoi
    // TODO: Mosaic
    FilterOperation(
        filter:{LocalBinaryPattern()},
        listName:"Local binary pattern",
        titleName:"Local Binary Pattern",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{ColorLocalBinaryPattern()},
        listName:"Local binary pattern (color)",
        titleName:"Local Binary Pattern (Color)",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.singleInput
    ),
    FilterOperation(
        filter:{DissolveBlend()},
        listName:"Dissolve blend",
        titleName:"Dissolve Blend",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.5),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.mix = sliderValue
        },
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{ChromaKeyBlend()},
        listName:"Chroma key blend (green)",
        titleName:"Chroma Key (Green)",
        sliderConfiguration:.enabled(minimumValue:0.0, maximumValue:1.0, initialValue:0.4),
        sliderUpdateCallback: {(filter, sliderValue) in
            filter.thresholdSensitivity = sliderValue
        },
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{AddBlend()},
        listName:"Add blend",
        titleName:"Add Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{DivideBlend()},
        listName:"Divide blend",
        titleName:"Divide Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{MultiplyBlend()},
        listName:"Multiply blend",
        titleName:"Multiply Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{OverlayBlend()},
        listName:"Overlay blend",
        titleName:"Overlay Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{LightenBlend()},
        listName:"Lighten blend",
        titleName:"Lighten Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{DarkenBlend()},
        listName:"Darken blend",
        titleName:"Darken Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{ColorBurnBlend()},
        listName:"Color burn blend",
        titleName:"Color Burn Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{ColorDodgeBlend()},
        listName:"Color dodge blend",
        titleName:"Color Dodge Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{LinearBurnBlend()},
        listName:"Linear burn blend",
        titleName:"Linear Burn Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback: nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{ScreenBlend()},
        listName:"Screen blend",
        titleName:"Screen Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{DifferenceBlend()},
        listName:"Difference blend",
        titleName:"Difference Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{SubtractBlend()},
        listName:"Subtract blend",
        titleName:"Subtract Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{ExclusionBlend()},
        listName:"Exclusion blend",
        titleName:"Exclusion Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{HardLightBlend()},
        listName:"Hard light blend",
        titleName:"Hard Light Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{SoftLightBlend()},
        listName:"Soft light blend",
        titleName:"Soft Light Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{ColorBlend()},
        listName:"Color blend",
        titleName:"Color Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{HueBlend()},
        listName:"Hue blend",
        titleName:"Hue Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{SaturationBlend()},
        listName:"Saturation blend",
        titleName:"Saturation Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{LuminosityBlend()},
        listName:"Luminosity blend",
        titleName:"Luminosity Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.blend
    ),
    FilterOperation(
        filter:{NormalBlend()},
        listName:"Normal blend",
        titleName:"Normal Blend",
        sliderConfiguration:.disabled,
        sliderUpdateCallback:nil,
        filterOperationType:.blend
    ),
    
    // TODO: Poisson blend
]
