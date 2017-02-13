# GPUImage 2 #

<div style="float: right"><img src="http://sunsetlakesoftware.com/sites/default/files/GPUImageLogo.png" /></div>

Brad Larson

http://www.sunsetlakesoftware.com

[@bradlarson](http://twitter.com/bradlarson)

contact@sunsetlakesoftware.com

## Overview ##

GPUImage 2 is the second generation of the <a href="https://github.com/BradLarson/GPUImage">GPUImage framework</a>, an open source project for performing GPU-accelerated image and video processing on Mac, iOS, and now Linux. The original GPUImage framework was written in Objective-C and targeted Mac and iOS, but this latest version is written entirely in Swift and can also target Linux and future platforms that support Swift code.

The objective of the framework is to make it as easy as possible to set up and perform realtime video processing or machine vision against image or video sources. By relying on the GPU to run these operations, performance improvements of 100X or more over CPU-bound code can be realized. This is particularly noticeable in mobile or embedded devices. On an iPhone 4S, this framework can easily process 1080p video at over 60 FPS. On a Raspberry Pi 3, it can perform Sobel edge detection on live 720p video at over 20 FPS.

## License ##

BSD-style, with the full license available with the framework in License.txt.

## Technical requirements ##

- Swift 3
- Xcode 8.0 on Mac or iOS
- iOS: 8.0 or higher (Swift is supported on 7.0, but not Mac-style frameworks)
- OSX: 10.9 or higher
- Linux: Wherever Swift code can be compiled. Currently, that's Ubuntu 14.04 or higher, along with the many other places it has been ported to. I've gotten this running on the latest Raspbian, for example. For camera input, Video4Linux needs to be installed.

## General architecture ##

The framework relies on the concept of a processing pipeline, where image sources are targeted at image consumers, and so on down the line until images are output to the screen, to image files, to raw data, or to recorded movies. Cameras, movies, still images, and raw data can be inputs into this pipeline. Arbitrarily complex processing operations can be built from a combination of a series of smaller operations.

This is an object-oriented framework, with classes that encapsulate inputs, processing operations, and outputs. The processing operations use Open GL (ES) vertex and fragment shaders to perform their image manipulations on the GPU.

Examples for usage of the framework in common applications are shown below.

## Using GPUImage in an Mac or iOS application ##

To add the GPUImage framework to your Mac or iOS application, either drag the GPUImage.xcodeproj project into your application's project or add it via File | Add Files To...

After that, go to your project's Build Phases and add GPUImage_iOS or GPUImage_macOS as a Target Dependency. Add it to the Link Binary With Libraries phase. Add a new Copy Files build phase, set its destination to Frameworks, and add the upper GPUImage.framework (for Mac) or lower GPUImage.framework (for iOS) to that. That last step will make sure the framework is deployed in your application bundle. 

In any of your Swift files that reference GPUImage classes, simply add

```swift
import GPUImage
```

and you should be ready to go.

Note that you may need to build your project once to parse and build the GPUImage framework in order for Xcode to stop warning you about the framework and its classes being missing.

## Using GPUImage in a Linux application ##

Eventually, this project will support the Swift Package Manager, which will make it trivial to use with a Linux project. Unfortunately, that's not yet the case, so it can take a little work to get this to build for a Linux project.

Right now, there are two build scripts in the framework directory, one named compile-LinuxGL.sh and one named compile-RPi.sh. The former builds the framework for a Linux target using OpenGL and the latter builds for the Raspberry Pi. I can add other targets as I test them, but I've only gotten this operational in desktop Ubuntu, on Ubuntu running on a Jetson TK1 development board, and on Raspbian running on a Raspberry Pi 2 and Pi 3.

Before compiling the framework, you'll need to get Swift up and running on your system. For desktop Ubuntu installs, you can follow Apple's guidelines on <a href="https://swift.org/download/">their Downloads page</a>. Those instructions also worked for me on the Jetson TK1 dev board.

For ARM Linux devices like the Raspberry Pi, follow <a href="http://dev.iachieved.it/iachievedit/open-source-swift-on-raspberry-pi-2/">these steps exactly</a> to get a working Swift compiler installed. Pay close attention to the steps for getting Clang-2.6 installed and the use of update-alternatives. These are the steps I used to go from stock Raspbian to a Swift install on 

I have noticed that Swift 2.2 compiler snapshots newer than January 11 or so are missing Foundation, which I need for the framework, so maybe go with a snaphot earlier than that. 

After Swift, you'll need to install Video4Linux to get access to standard USB webcams as inputs:

```
sudo apt-get install libv4l-dev
```

On the Raspberry Pi, you'll need to make sure that the Broadcom Videocore headers and libraries are installed for GPU access:

```
sudo apt-get install libraspberrypi-dev
```

For desktop Linux and other OpenGL devices (Jetson TK1), you'll need to make sure GLUT and the OpenGL headers are installed. The framework currently uses GLUT for its output. GLUT can be used on the Raspberry Pi via the new experimental OpenGL support there, but I've found that it's significantly slower than using the OpenGL ES APIs and the Videocore interface that ships with the Pi. Also, if you enable the OpenGL support you currently lock yourself out of using the Videocore interface.

Once all of that is set up, to build the framework go to the /framework directory and run the appropriate build script. This will compile and generate a Swift module and a shared library for the framework. Copy the shared library into a system-accessible library path, like /usr/lib.

To build any of the sample applications, go to the examples/ subdirectory for that example (examples are platform-specific) and run the compile.sh build script to compile the example. The framework must be built before any example application.

As Swift becomes incorporated into more platforms, and as I add support for the Swift Package Manager, these Linux build steps will become much easier. My setup is kind of a hack at present.

## Performing common tasks ##

### Filtering live video ###

To filter live video from a Mac or iOS camera, you can write code like the following:

```swift
do {
    camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
    filter = SaturationAdjustment()
    camera --> filter --> renderView
    camera.startCapture()
} catch {
    fatalError("Could not initialize rendering pipeline: \(error)")
}
```

where renderView is an instance of RenderView that you've placed somewhere in your view hierarchy. The above instantiates a 640x480 camera instance, creates a saturation filter, and directs camera frames to be processed through the saturation filter on their way to the screen. startCapture() initiates the camera capture process.

The --> operator chains an image source to an image consumer, and many of these can be chained in the same line.

### Capturing and filtering a still photo ###

Functionality not completed.

### Capturing an image from video ###

(Not currently available on Linux.)

To capture a still image from live video, you need to set a callback to be performed on the next frame of video that is processed. The easiest way to do this is to use the convenience extension to capture, encode, and save a file to disk:

```swift
filter.saveNextFrameToURL(url, format:.PNG)
```

Under the hood, this creates a PictureOutput instance, attaches it as a target to your filter, sets the PictureOutput's encodedImageFormat to PNG files, and sets the encodedImageAvailableCallback to a closure that takes in the data for the filtered image and saves it to a URL.

You can set this up manually to get the encoded image data (as NSData):

```swift
let pictureOutput = PictureOutput()
pictureOutput.encodedImageFormat = .JPEG
pictureOutput.encodedImageAvailableCallback = {imageData in
    // Do something with the NSData
}
filter --> pictureOutput
```

You can also get the filtered image in a platform-native format (NSImage, UIImage) by setting the imageAvailableCallback:

```swift
let pictureOutput = PictureOutput()
pictureOutput.encodedImageFormat = .JPEG
pictureOutput.imageAvailableCallback = {image in
    // Do something with the image
}
filter --> pictureOutput
```

### Processing a still image ###

(Not currently available on Linux.)

There are a few different ways to approach filtering an image. The easiest are the convenience extensions to UIImage or NSImage that let you filter that image and return a UIImage or NSImage:

```swift
let testImage = UIImage(named:"WID-small.jpg")!
let toonFilter = SmoothToonFilter()
let filteredImage = testImage.filterWithOperation(toonFilter)
```

for a more complex pipeline:

```swift
let testImage = UIImage(named:"WID-small.jpg")!
let toonFilter = SmoothToonFilter()
let luminanceFilter = Luminance()
let filteredImage = testImage.filterWithPipeline{input, output in
    input --> toonFilter --> luminanceFilter --> output
}
```

One caution: if you want to display an image to the screen or repeatedly filter an image, don't use these methods. Going to and from Core Graphics adds a lot of overhead. Instead, I recommend manually setting up a pipeline and directing it to a RenderView for display in order to keep everything on the GPU.

Both of these convenience methods wrap several operations. To feed a picture into a filter pipeline, you instantiate a PictureInput. To capture a picture from the pipeline, you use a PictureOutput. To manually set up processing of an image, you can use something like the following:

```swift
let toonFilter = SmoothToonFilter()
let testImage = UIImage(named:"WID-small.jpg")!
let pictureInput = PictureInput(image:testImage)
let pictureOutput = PictureOutput()
pictureOutput.imageAvailableCallback = {image in
    // Do something with image
}
pictureInput --> toonFilter --> pictureOutput
pictureInput.processImage(synchronously:true)
```

In the above, the imageAvailableCallback will be triggered right at the processImage() line. If you want the image processing to be done asynchronously, leave out the synchronously argument in the above.

### Filtering and re-encoding a movie ###

To filter an existing movie file, you can write code like the following:

```swift

do {
	let bundleURL = Bundle.main.resourceURL!
	let movieURL = URL(string:"sample_iPod.m4v", relativeTo:bundleURL)!
	movie = try MovieInput(url:movieURL, playAtActualSpeed:true)
    filter = SaturationAdjustment()
    movie --> filter --> renderView
    movie.start()
} catch {
    fatalError("Could not initialize rendering pipeline: \(error)")
}
```

where renderView is an instance of RenderView that you've placed somewhere in your view hierarchy. The above loads a movie named "sample_iPod.m4v" from the application's bundle, creates a saturation filter, and directs movie frames to be processed through the saturation filter on their way to the screen. start() initiates the movie playback.

### Writing a custom image processing operation ###

The framework uses a series of protocols to define types that can output images to be processed, take in an image for processing, or do both. These are the ImageSource, ImageConsumer, and ImageProcessingOperation protocols, respectively. Any type can comply to these, but typically classes are used.

Many common filters and other image processing operations can be described as subclasses of the BasicOperation class. BasicOperation provides much of the internal code required for taking in an image frame from one or more inputs, rendering a rectangular image (quad) from those inputs using a specified shader program, and providing that image to all of its targets. Variants on BasicOperation, such as TextureSamplingOperation or TwoStageOperation, provide additional information to the shader program that may be needed for certain kinds of operations.

To build a simple, one-input filter, you may not even need to create a subclass of your own. All you need to do is supply a fragment shader and the number of inputs needed when instantiating a BasicOperation:

```swift
let myFilter = BasicOperation(fragmentShaderFile:MyFilterFragmentShaderURL, numberOfInputs:1)
```

A shader program is composed of matched vertex and fragment shaders that are compiled and linked together into one program. By default, the framework uses a series of stock vertex shaders based on the number of input images feeding into an operation. Usually, all you'll need to do is provide the custom fragment shader that is used to perform your filtering or other processing.

Fragment shaders used by GPUImage look something like this:

```
varying highp vec2 textureCoordinate;

uniform sampler2D inputImageTexture;
uniform lowp float gamma;

void main()
{
    lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    
    gl_FragColor = vec4(pow(textureColor.rgb, vec3(gamma)), textureColor.w);
}
```

The naming convention for texture coordinates is that textureCoordinate, textureCoordinate2, etc. are provided as varyings from the vertex shader. inputImageTexture, inputImageTexture2, etc. are the textures that represent each image being passed into the shader program. Uniforms can be defined to control the properties of whatever shader you're running. You'll need to provide two fragment shaders, one for OpenGL ES, which has precision qualifiers, and one for OpenGL, which does not.

Within the framework itself, a custom script converts these shader files into inlined string constants so that they are bundled with the compiled framework. If you add a new operation to the framework, you'll need to run

```
./ShaderConverter.sh *
```

within the Operations/Shaders directory to update these inlined constants.

### Grouping operations ###

If you wish to group a series of operations into a single unit to pass around, you can create a new instance of OperationGroup. OperationGroup provides a configureGroup property that takes a closure which specifies how the group should be configured:

```swift
let boxBlur = BoxBlur()
let contrast = ContrastAdjustment()

let myGroup = OperationGroup()

myGroup.configureGroup{input, output in
    input --> self.boxBlur --> self.contrast --> output
}
```

Frames coming in to the OperationGroup are represented by the input in the above closure, and frames going out of the entire group by the output. After setup, myGroup in the above will appear like any other operation, even though it is composed of multiple sub-operations. This group can then be passed or worked with like a single operation.

### Interacting with OpenGL / OpenGL ES ###

GPUImage can both export and import textures from OpenGL (ES) through the use of its TextureOutput and TextureInput classes, respectively. This lets you record a movie from an OpenGL scene that is rendered to a framebuffer object with a bound texture, or filter video or images and then feed them into OpenGL as a texture to be displayed in the scene.

The one caution with this approach is that the textures used in these processes must be shared between GPUImage's OpenGL (ES) context and any other context via a share group or something similar.

## Common types ##

The framework uses several platform-independent types to represent common values. Generally, floating-point inputs are taken in as Floats. Sizes are specified using Size types (constructed by initializing with width and height). Colors are handled via the Color type, where you provide the normalized-to-1.0 color values for red, green, blue, and optionally alpha components.

Positions can be provided in 2-D and 3-D coordinates. If a Position is created by only specifying X and Y values, it will be handled as a 2-D point. If an optional Z coordinate is also provided, it will be dealt with as a 3-D point.

Matrices come in Matrix3x3 and Matrix4x4 varieties. These matrices can be build using a row-major array of Floats, or (on Mac and iOS) can be initialized from CATransform3D or CGAffineTransform structs.

## Built-in operations ##

There are currently over 100 operations built into the framework, divided into the following categories:

### Image generators ###

- **SolidColorGenerator**: This outputs a generated image with a solid color. You need to define the image size using at initialization.
  - *color*: The color that is used to fill the image.

- **CircleGenerator**: This outputs a generated image of a circle, for use in masking. The renderCircleOfRadius() method lets you specify the radius, center, circleColor, and backgroundColor.
  
- **CrosshairGenerator**: This outputs a generated image of a circle, for use in masking. The renderCrosshairs() takes in a series of normalized coordinates and draws crosshairs at those coordinates.
  - *crosshairWidth*: Width, in pixels, of the crosshairs that are drawn.
  - *crosshairColor*: The color of the crosshairs.

### Color adjustments ###

- **BrightnessAdjustment**: Adjusts the brightness of the image
  - *brightness*: The adjusted brightness (-1.0 - 1.0, with 0.0 as the default)

- **ExposureAdjustment**: Adjusts the exposure of the image
  - *exposure*: The adjusted exposure (-10.0 - 10.0, with 0.0 as the default)

- **ContrastAdjustment**: Adjusts the contrast of the image
  - *contrast*: The adjusted contrast (0.0 - 4.0, with 1.0 as the default)

- **SaturationAdjustment**: Adjusts the saturation of an image
  - *saturation*: The degree of saturation or desaturation to apply to the image (0.0 - 2.0, with 1.0 as the default)

- **GammaAdjustment**: Adjusts the gamma of an image
  - *gamma*: The gamma adjustment to apply (0.0 - 3.0, with 1.0 as the default)

- **LevelsAdjustment**: Photoshop-like levels adjustment. The minimum, middle, maximum, minOutput and maxOutput parameters are floats in the range [0, 1]. If you have parameters from Photoshop in the range [0, 255] you must first convert them to be [0, 1]. The gamma/mid parameter is a float >= 0. This matches the value from Photoshop. If you want to apply levels to RGB as well as individual channels you need to use this filter twice - first for the individual channels and then for all channels.

- **ColorMatrixFilter**: Transforms the colors of an image by applying a matrix to them
  - *colorMatrix*: A 4x4 matrix used to transform each color in an image
  - *intensity*: The degree to which the new transformed color replaces the original color for each pixel

- **RGBAdjustment**: Adjusts the individual RGB channels of an image
  - *red*: Normalized values by which each color channel is multiplied. The range is from 0.0 up, with 1.0 as the default.
  - *green*: 
  - *blue*:

- **HueAdjustment**: Adjusts the hue of an image
  - *hue*: The hue angle, in degrees. 90 degrees by default

- **WhiteBalance**: Adjusts the white balance of an image.
  - *temperature*: The temperature to adjust the image by, in ºK. A value of 4000 is very cool and 7000 very warm. The default value is 5000. Note that the scale between 4000 and 5000 is nearly as visually significant as that between 5000 and 7000.
  - *tint*: The tint to adjust the image by. A value of -200 is *very* green and 200 is *very* pink. The default value is 0.  

- **HighlightsAndShadows**: Adjusts the shadows and highlights of an image
  - *shadows*: Increase to lighten shadows, from 0.0 to 1.0, with 0.0 as the default.
  - *highlights*: Decrease to darken highlights, from 1.0 to 0.0, with 1.0 as the default.

- **LookupFilter**: Uses an RGB color lookup image to remap the colors in an image. First, use your favourite photo editing application to apply a filter to lookup.png from framework/Operations/LookupImages. For this to work properly each pixel color must not depend on other pixels (e.g. blur will not work). If you need a more complex filter you can create as many lookup tables as required. Once ready, use your new lookup.png file as  the basis of a PictureInput that you provide for the lookupImage property.
  - *intensity*: The intensity of the applied effect, from 0.0 (stock image) to 1.0 (fully applied effect).
  - *lookupImage*: The image to use as the lookup reference, in the form of a PictureInput.

- **AmatorkaFilter**: A photo filter based on a Photoshop action by Amatorka: http://amatorka.deviantart.com/art/Amatorka-Action-2-121069631 . If you want to use this effect you have to add lookup_amatorka.png from the GPUImage framework/Operations/LookupImages folder to your application bundle.

- **MissEtikateFilter**: A photo filter based on a Photoshop action by Miss Etikate: http://miss-etikate.deviantart.com/art/Photoshop-Action-15-120151961 . If you want to use this effect you have to add lookup_miss_etikate.png from the GPUImage framework/Operations/LookupImages folder to your application bundle.

- **SoftElegance**: Another lookup-based color remapping filter. If you want to use this effect you have to add lookup_soft_elegance_1.png and lookup_soft_elegance_2.png from the GPUImage framework/Operations/LookupImages folder to your application bundle.

- **ColorInversion**: Inverts the colors of an image

- **Luminance**: Reduces an image to just its luminance (greyscale).

- **MonochromeFilter**: Converts the image to a single-color version, based on the luminance of each pixel
  - *intensity*: The degree to which the specific color replaces the normal image color (0.0 - 1.0, with 1.0 as the default)
  - *color*: The color to use as the basis for the effect, with (0.6, 0.45, 0.3, 1.0) as the default.

- **FalseColor**: Uses the luminance of the image to mix between two user-specified colors
  - *firstColor*: The first and second colors specify what colors replace the dark and light areas of the image, respectively. The defaults are (0.0, 0.0, 0.5) amd (1.0, 0.0, 0.0).
  - *secondColor*: 

- **Haze**: Used to add or remove haze (similar to a UV filter)
  - *distance*: Strength of the color applied. Default 0. Values between -.3 and .3 are best.
  - *slope*: Amount of color change. Default 0. Values between -.3 and .3 are best.

- **SepiaToneFilter**: Simple sepia tone filter
  - *intensity*: The degree to which the sepia tone replaces the normal image color (0.0 - 1.0, with 1.0 as the default)

- **OpacityAdjustment**: Adjusts the alpha channel of the incoming image
  - *opacity*: The value to multiply the incoming alpha channel for each pixel by (0.0 - 1.0, with 1.0 as the default)

- **LuminanceThreshold**: Pixels with a luminance above the threshold will appear white, and those below will be black
  - *threshold*: The luminance threshold, from 0.0 to 1.0, with a default of 0.5

- **AdaptiveThreshold**: Determines the local luminance around a pixel, then turns the pixel black if it is below that local luminance and white if above. This can be useful for picking out text under varying lighting conditions.
  - *blurRadiusInPixels*: A multiplier for the background averaging blur radius in pixels, with a default of 4.

- **AverageLuminanceThreshold**: This applies a thresholding operation where the threshold is continually adjusted based on the average luminance of the scene.
  - *thresholdMultiplier*: This is a factor that the average luminance will be multiplied by in order to arrive at the final threshold to use. By default, this is 1.0.

- **AverageColorExtractor**: This processes an input image and determines the average color of the scene, by averaging the RGBA components for each pixel in the image. A reduction process is used to progressively downsample the source image on the GPU, followed by a short averaging calculation on the CPU. The output from this filter is meaningless, but you need to set the colorAverageProcessingFinishedBlock property to a block that takes in four color components and a frame time and does something with them.

- **AverageLuminanceExtractor**: Like the AverageColorExtractor, this reduces an image to its average luminosity. You need to set the luminosityProcessingFinishedBlock to handle the output of this filter, which just returns a luminosity value and a frame time.

- **ChromaKeying**: For a given color in the image, sets the alpha channel to 0. This is similar to the ChromaKeyBlend, only instead of blending in a second image for a matching color this doesn't take in a second image and just turns a given color transparent.
  - *thresholdSensitivity*: How close a color match needs to exist to the target color to be replaced (default of 0.4)
  - *smoothing*: How smoothly to blend for the color match (default of 0.1)

- **Vibrance**: Adjusts the vibrance of an image
  - *vibrance*: The vibrance adjustment to apply, using 0.0 as the default, and a suggested min/max of around -1.2 and 1.2, respectively.

- **HighlightShadowTint**: Allows you to tint the shadows and highlights of an image independently using a color and intensity
  - *shadowTintColor*: Shadow tint RGB color (GPUVector4). Default: `{1.0f, 0.0f, 0.0f, 1.0f}` (red).
  - *highlightTintColor*: Highlight tint RGB color (GPUVector4). Default: `{0.0f, 0.0f, 1.0f, 1.0f}` (blue).
  - *shadowTintIntensity*: Shadow tint intensity, from 0.0 to 1.0. Default: 0.0
  - *highlightTintIntensity*: Highlight tint intensity, from 0.0 to 1.0, with 0.0 as the default.

### Image processing ###

- **TransformOperation**: This applies an arbitrary 2-D or 3-D transformation to an image
  - *transform*: This takes in Matrix4x4 row-major value that specifies the transform. Matrix4x4 values can be initialized from both CATransform3D (for 3-D manipulations) and CGAffineTransform (for 2-D) structs on Mac and iOS, or the matrix can be generated by other means.

- **Crop**: This crops an image to a specific region, then passes only that region on to the next stage in the filter
  - *cropSizeInPixels*: The pixel dimensions of the area to be cropped out of the image.
  - *locationOfCropInPixels*: The upper-left corner of the crop area. If not specified, the crop will be centered in the image.

- **LanczosResampling**: This lets you up- or downsample an image using Lanczos resampling, which results in noticeably better quality than the standard linear or trilinear interpolation. Simply use the overriddenOutputSize propety to set the target output resolution for the filter, and the image will be resampled for that new size.

- **Sharpen**: Sharpens the image
  - *sharpness*: The sharpness adjustment to apply (-4.0 - 4.0, with 0.0 as the default)

- **UnsharpMask**: Applies an unsharp mask
  - *blurRadiusInPixels*: The blur radius of the underlying Gaussian blur. The default is 4.0.
  - *intensity*: The strength of the sharpening, from 0.0 on up, with a default of 1.0

- **GaussianBlur**: A hardware-optimized, variable-radius Gaussian blur
  - *blurRadiusInPixels*: A radius in pixels to use for the blur, with a default of 2.0. This adjusts the sigma variable in the Gaussian distribution function.

- **BoxBlur**: A hardware-optimized, variable-radius box blur
  - *blurRadiusInPixels*: A radius in pixels to use for the blur, with a default of 2.0. This adjusts the box radius for the blur function.

- **SingleComponentGaussianBlur**: A modification of the GaussianBlur that operates only on the red component
  - *blurRadiusInPixels*: A radius in pixels to use for the blur, with a default of 2.0. This adjusts the sigma variable in the Gaussian distribution function.

- **iOSBlur**: An attempt to replicate the background blur used on iOS 7 in places like the control center.
  - *blurRadiusInPixels*: A radius in pixels to use for the blur, with a default of 48.0. This adjusts the sigma variable in the Gaussian distribution function.
  - *saturation*: Saturation ranges from 0.0 (fully desaturated) to 2.0 (max saturation), with 0.8 as the normal level
  - *rangeReductionFactor*: The range to reduce the luminance of the image, defaulting to 0.6.

- **MedianFilter**: Takes the median value of the three color components, over a 3x3 area

- **BilateralBlur**: A bilateral blur, which tries to blur similar color values while preserving sharp edges
  - *distanceNormalizationFactor*: A normalization factor for the distance between central color and sample color, with a default of 8.0.

- **TiltShift**: A simulated tilt shift lens effect
  - *blurRadiusInPixels*: The radius of the underlying blur, in pixels. This is 7.0 by default.
  - *topFocusLevel*: The normalized location of the top of the in-focus area in the image, this value should be lower than bottomFocusLevel, default 0.4
  - *bottomFocusLevel*: The normalized location of the bottom of the in-focus area in the image, this value should be higher than topFocusLevel, default 0.6
  - *focusFallOffRate*: The rate at which the image gets blurry away from the in-focus region, default 0.2

- **Convolution3x3**: Runs a 3x3 convolution kernel against the image
  - *convolutionKernel*: The convolution kernel is a 3x3 matrix of values to apply to the pixel and its 8 surrounding pixels. The matrix is specified in row-major order, with the top left pixel being m11 and the bottom right m33. If the values in the matrix don't add up to 1.0, the image could be brightened or darkened.

- **SobelEdgeDetection**: Sobel edge detection, with edges highlighted in white
  - *edgeStrength*: Adjusts the dynamic range of the filter. Higher values lead to stronger edges, but can saturate the intensity colorspace. Default is 1.0.

- **PrewittEdgeDetection**: Prewitt edge detection, with edges highlighted in white
  - *edgeStrength*: Adjusts the dynamic range of the filter. Higher values lead to stronger edges, but can saturate the intensity colorspace. Default is 1.0.

- **ThresholdSobelEdgeDetection**: Performs Sobel edge detection, but applies a threshold instead of giving gradual strength values
  - *edgeStrength*: Adjusts the dynamic range of the filter. Higher values lead to stronger edges, but can saturate the intensity colorspace. Default is 1.0.
  - *threshold*: Any edge above this threshold will be black, and anything below white. Ranges from 0.0 to 1.0, with 0.8 as the default
  
- **Histogram**: This analyzes the incoming image and creates an output histogram with the frequency at which each color value occurs. The output of this filter is a 3-pixel-high, 256-pixel-wide image with the center (vertical) pixels containing pixels that correspond to the frequency at which various color values occurred. Each color value occupies one of the 256 width positions, from 0 on the left to 255 on the right. This histogram can be generated for individual color channels (.Red, .Green, .Blue), the luminance of the image (.Luminance), or for all three color channels at once (.RGB).
  - *downsamplingFactor*: Rather than sampling every pixel, this dictates what fraction of the image is sampled. By default, this is 16 with a minimum of 1. This is needed to keep from saturating the histogram, which can only record 256 pixels for each color value before it becomes overloaded.

- **HistogramDisplay**: This is a special filter, in that it's primarily intended to work with the Histogram. It generates an output representation of the color histograms generated by Histogram, but it could be repurposed to display other kinds of values. It takes in an image and looks at the center (vertical) pixels. It then plots the numerical values of the RGB components in separate colored graphs in an output texture. You may need to force a size for this filter in order to make its output visible.

- **HistogramEqualization**: This takes a image, analyzes its histogram, and equalizes the outbound image based on that.
  - *downsamplingFactor*: Rather than sampling every pixel, this dictates what fraction of the image is sampled by the histogram. By default, this is 16 with a minimum of 1. This is needed to keep from saturating the histogram, which can only record 256 pixels for each color value before it becomes overloaded.

- **CannyEdgeDetection**: This uses the full Canny process to highlight one-pixel-wide edges
  - *blurRadiusInPixels*: The underlying blur radius for the Gaussian blur. Default is 2.0.
  - *upperThreshold*: Any edge with a gradient magnitude above this threshold will pass and show up in the final result. Default is 0.4.
  - *lowerThreshold*: Any edge with a gradient magnitude below this threshold will fail and be removed from the final result. Default is 0.1.

- **HarrisCornerDetector**: Runs the Harris corner detection algorithm on an input image, and produces an image with those corner points as white pixels and everything else black. The cornersDetectedCallback can be set, and you will be provided with an array of corners (in normalized 0..1 Positions) within that callback for whatever additional operations you want to perform.
  - *blurRadiusInPixels*: The radius of the underlying Gaussian blur. The default is 2.0.
  - *sensitivity*: An internal scaling factor applied to adjust the dynamic range of the cornerness maps generated in the filter. The default is 5.0.
  - *threshold*: The threshold at which a point is detected as a corner. This can vary significantly based on the size, lighting conditions, and iOS device camera type, so it might take a little experimentation to get right for your cases. Default is 0.20.

- **NobleCornerDetector**: Runs the Noble variant on the Harris corner detector. It behaves as described above for the Harris detector.
  - *blurRadiusInPixels*: The radius of the underlying Gaussian blur. The default is 2.0.
  - *sensitivity*: An internal scaling factor applied to adjust the dynamic range of the cornerness maps generated in the filter. The default is 5.0.
  - *threshold*: The threshold at which a point is detected as a corner. This can vary significantly based on the size, lighting conditions, and iOS device camera type, so it might take a little experimentation to get right for your cases. Default is 0.2.

- **ShiTomasiCornerDetector**: Runs the Shi-Tomasi feature detector. It behaves as described above for the Harris detector.
  - *blurRadiusInPixels*: The radius of the underlying Gaussian blur. The default is 2.0.
  - *sensitivity*: An internal scaling factor applied to adjust the dynamic range of the cornerness maps generated in the filter. The default is 1.5.
  - *threshold*: The threshold at which a point is detected as a corner. This can vary significantly based on the size, lighting conditions, and iOS device camera type, so it might take a little experimentation to get right for your cases. Default is 0.2.

- **Dilation**: This performs an image dilation operation, where the maximum intensity of the color channels in a rectangular neighborhood is used for the intensity of this pixel. The radius of the rectangular area to sample over is specified on initialization, with a range of 1-4 pixels. This is intended for use with grayscale images, and it expands bright regions.

- **Erosion**: This performs an image erosion operation, where the minimum intensity of the color channels in a rectangular neighborhood is used for the intensity of this pixel. The radius of the rectangular area to sample over is specified on initialization, with a range of 1-4 pixels. This is intended for use with grayscale images, and it expands dark regions.

- **OpeningFilter**: This performs an erosion on the color channels of an image, followed by a dilation of the same radius. The radius is set on initialization, with a range of 1-4 pixels. This filters out smaller bright regions.

- **ClosingFilter**: This performs a dilation on the color channels of an image, followed by an erosion of the same radius. The radius is set on initialization, with a range of 1-4 pixels. This filters out smaller dark regions.

- **LocalBinaryPattern**: This performs a comparison of intensity of the red channel of the 8 surrounding pixels and that of the central one, encoding the comparison results in a bit string that becomes this pixel intensity. The least-significant bit is the top-right comparison, going counterclockwise to end at the right comparison as the most significant bit.

- **ColorLocalBinaryPattern**: This performs a comparison of intensity of all color channels of the 8 surrounding pixels and that of the central one, encoding the comparison results in a bit string that becomes each color channel's intensity. The least-significant bit is the top-right comparison, going counterclockwise to end at the right comparison as the most significant bit.

- **LowPassFilter**: This applies a low pass filter to incoming video frames. This basically accumulates a weighted rolling average of previous frames with the current ones as they come in. This can be used to denoise video, add motion blur, or be used to create a high pass filter.
  - *strength*: This controls the degree by which the previous accumulated frames are blended with the current one. This ranges from 0.0 to 1.0, with a default of 0.5.

- **HighPassFilter**: This applies a high pass filter to incoming video frames. This is the inverse of the low pass filter, showing the difference between the current frame and the weighted rolling average of previous ones. This is most useful for motion detection.
  - *strength*: This controls the degree by which the previous accumulated frames are blended and then subtracted from the current one. This ranges from 0.0 to 1.0, with a default of 0.5.

- **MotionDetector**: This is a motion detector based on a high-pass filter. You set the motionDetectedCallback and on every incoming frame it will give you the centroid of any detected movement in the scene (in normalized X,Y coordinates) as well as an intensity of motion for the scene.
  - *lowPassStrength*: This controls the strength of the low pass filter used behind the scenes to establish the baseline that incoming frames are compared with. This ranges from 0.0 to 1.0, with a default of 0.5.

- **MotionBlur**: Applies a directional motion blur to an image
  - *blurSize*: A multiplier for the blur size, ranging from 0.0 on up, with a default of 1.0
  - *blurAngle*: The angular direction of the blur, in degrees. 0 degrees by default.

- **ZoomBlur**: Applies a directional motion blur to an image
  - *blurSize*: A multiplier for the blur size, ranging from 0.0 on up, with a default of 1.0
  - *blurCenter*: The normalized center of the blur. (0.5, 0.5) by default

- **ColourFASTFeatureDetection**: Brings out the ColourFAST feature descriptors for an image
  - *blurRadiusInPixels*: The underlying blur radius for the box blur. Default is 3.0.

### Blending modes ###

- **ChromaKeyBlend**: Selectively replaces a color in the first image with the second image
  - *thresholdSensitivity*: How close a color match needs to exist to the target color to be replaced (default of 0.4)
  - *smoothing*: How smoothly to blend for the color match (default of 0.1)

- **DissolveBlend**: Applies a dissolve blend of two images
  - *mix*: The degree with which the second image overrides the first (0.0 - 1.0, with 0.5 as the default)

- **MultiplyBlend**: Applies a multiply blend of two images

- **AddBlend**: Applies an additive blend of two images

- **SubtractBlend**: Applies a subtractive blend of two images

- **DivideBlend**: Applies a division blend of two images

- **OverlayBlend**: Applies an overlay blend of two images

- **DarkenBlend**: Blends two images by taking the minimum value of each color component between the images

- **LightenBlend**: Blends two images by taking the maximum value of each color component between the images

- **ColorBurnBlend**: Applies a color burn blend of two images

- **ColorDodgeBlend**: Applies a color dodge blend of two images

- **ScreenBlend**: Applies a screen blend of two images

- **ExclusionBlend**: Applies an exclusion blend of two images

- **DifferenceBlend**: Applies a difference blend of two images

- **HardLightBlend**: Applies a hard light blend of two images

- **SoftLightBlend**: Applies a soft light blend of two images

- **AlphaBlend**: Blends the second image over the first, based on the second's alpha channel
  - *mix*: The degree with which the second image overrides the first (0.0 - 1.0, with 1.0 as the default)

- **SourceOverBlend**: Applies a source over blend of two images

- **ColorBurnBlend**: Applies a color burn blend of two images

- **ColorDodgeBlend**: Applies a color dodge blend of two images

- **NormalBlend**: Applies a normal blend of two images

- **ColorBlend**: Applies a color blend of two images

- **HueBlend**: Applies a hue blend of two images

- **SaturationBlend**: Applies a saturation blend of two images

- **LuminosityBlend**: Applies a luminosity blend of two images

- **LinearBurnBlend**: Applies a linear burn blend of two images

### Visual effects ###

- **Pixellate**: Applies a pixellation effect on an image or video
  - *fractionalWidthOfAPixel*: How large the pixels are, as a fraction of the width and height of the image (0.0 - 1.0, default 0.05)

- **PolarPixellate**: Applies a pixellation effect on an image or video, based on polar coordinates instead of Cartesian ones
  - *center*: The center about which to apply the pixellation, defaulting to (0.5, 0.5)
  - *pixelSize*: The fractional pixel size, split into width and height components. The default is (0.05, 0.05)

- **PolkaDot**: Breaks an image up into colored dots within a regular grid
  - *fractionalWidthOfAPixel*: How large the dots are, as a fraction of the width and height of the image (0.0 - 1.0, default 0.05)
  - *dotScaling*: What fraction of each grid space is taken up by a dot, from 0.0 to 1.0 with a default of 0.9.

- **Halftone**: Applies a halftone effect to an image, like news print
  - *fractionalWidthOfAPixel*: How large the halftone dots are, as a fraction of the width and height of the image (0.0 - 1.0, default 0.05)

- **Crosshatch**: This converts an image into a black-and-white crosshatch pattern
  - *crossHatchSpacing*: The fractional width of the image to use as the spacing for the crosshatch. The default is 0.03.
  - *lineWidth*: A relative width for the crosshatch lines. The default is 0.003.

- **SketchFilter**: Converts video to look like a sketch. This is just the Sobel edge detection filter with the colors inverted
  - *edgeStrength*: Adjusts the dynamic range of the filter. Higher values lead to stronger edges, but can saturate the intensity colorspace. Default is 1.0.

- **ThresholdSketchFilter**: Same as the sketch filter, only the edges are thresholded instead of being grayscale
  - *edgeStrength*: Adjusts the dynamic range of the filter. Higher values lead to stronger edges, but can saturate the intensity colorspace. Default is 1.0.
  - *threshold*: Any edge above this threshold will be black, and anything below white. Ranges from 0.0 to 1.0, with 0.8 as the default

- **ToonFilter**: This uses Sobel edge detection to place a black border around objects, and then it quantizes the colors present in the image to give a cartoon-like quality to the image.
  - *threshold*: The sensitivity of the edge detection, with lower values being more sensitive. Ranges from 0.0 to 1.0, with 0.2 as the default
  - *quantizationLevels*: The number of color levels to represent in the final image. Default is 10.0

- **SmoothToonFilter**: This uses a similar process as the ToonFilter, only it precedes the toon effect with a Gaussian blur to smooth out noise.
  - *blurRadiusInPixels*: The radius of the underlying Gaussian blur. The default is 2.0.
  - *threshold*: The sensitivity of the edge detection, with lower values being more sensitive. Ranges from 0.0 to 1.0, with 0.2 as the default
  - *quantizationLevels*: The number of color levels to represent in the final image. Default is 10.0

- **EmbossFilter**: Applies an embossing effect on the image
  - *intensity*: The strength of the embossing, from  0.0 to 4.0, with 1.0 as the normal level

- **Posterize**: This reduces the color dynamic range into the number of steps specified, leading to a cartoon-like simple shading of the image.
  - *colorLevels*: The number of color levels to reduce the image space to. This ranges from 1 to 256, with a default of 10.

- **SwirlDistortion**: Creates a swirl distortion on the image
  - *radius*: The radius from the center to apply the distortion, with a default of 0.5
  - *center*: The center of the image (in normalized coordinates from 0 - 1.0) about which to twist, with a default of (0.5, 0.5)
  - *angle*: The amount of twist to apply to the image, with a default of 1.0

- **BulgeDistortion**: Creates a bulge distortion on the image
  - *radius*: The radius from the center to apply the distortion, with a default of 0.25
  - *center*: The center of the image (in normalized coordinates from 0 - 1.0) about which to distort, with a default of (0.5, 0.5)
  - *scale*: The amount of distortion to apply, from -1.0 to 1.0, with a default of 0.5

- **PinchDistortion**: Creates a pinch distortion of the image
  - *radius*: The radius from the center to apply the distortion, with a default of 1.0
  - *center*: The center of the image (in normalized coordinates from 0 - 1.0) about which to distort, with a default of (0.5, 0.5)
  - *scale*: The amount of distortion to apply, from -2.0 to 2.0, with a default of 1.0

- **StretchDistortion**: Creates a stretch distortion of the image
  - *center*: The center of the image (in normalized coordinates from 0 - 1.0) about which to distort, with a default of (0.5, 0.5)

- **SphereRefraction**: Simulates the refraction through a glass sphere
  - *center*: The center about which to apply the distortion, with a default of (0.5, 0.5)
  - *radius*: The radius of the distortion, ranging from 0.0 to 1.0, with a default of 0.25
  - *refractiveIndex*: The index of refraction for the sphere, with a default of 0.71

- **GlassSphereRefraction**: Same as SphereRefraction, only the image is not inverted and there's a little bit of frosting at the edges of the glass
  - *center*: The center about which to apply the distortion, with a default of (0.5, 0.5)
  - *radius*: The radius of the distortion, ranging from 0.0 to 1.0, with a default of 0.25
  - *refractiveIndex*: The index of refraction for the sphere, with a default of 0.71

- **Vignette**: Performs a vignetting effect, fading out the image at the edges
  - *center*: The center for the vignette in tex coords (CGPoint), with a default of 0.5, 0.5
  - *color*: The color to use for the vignette (GPUVector3), with a default of black
  - *start*: The normalized distance from the center where the vignette effect starts, with a default of 0.5
  - *end*: The normalized distance from the center where the vignette effect ends, with a default of 0.75

- **KuwaharaFilter**: Kuwahara image abstraction, drawn from the work of Kyprianidis, et. al. in their publication "Anisotropic Kuwahara Filtering on the GPU" within the GPU Pro collection. This produces an oil-painting-like image, but it is extremely computationally expensive, so it can take seconds to render a frame on an iPad 2. This might be best used for still images.
  - *radius*: In integer specifying the number of pixels out from the center pixel to test when applying the filter, with a default of 4. A higher value creates a more abstracted image, but at the cost of much greater processing time.

- **KuwaharaRadius3Filter**: A modified version of the Kuwahara filter, optimized to work over just a radius of three pixels

- **CGAColorspace**: Simulates the colorspace of a CGA monitor

- **Solarize**: Applies a solarization effect
  - *threshold*: Pixels with a luminance above the threshold will invert their color. Ranges from 0.0 to 1.0, with 0.5 as the default.

