import GPUImage
import Foundation

// For now, GLUT initialization is done in the render window, so that must come first in sequence
let renderWindow = GLUTRenderWindow(width:1280, height:720, title:"Simple Video Filter", offscreen:false)
guard let pictureInput = PictureInput(path:"../../SharedAssets/Lambeau.jpg") else {
    fatalError("Could not load sample image")
}
let edgeDetection = SobelEdgeDetection()
let pictureOutput = PictureOutput()

pictureInput --> edgeDetection --> renderWindow
pictureInput --> pictureOutput

pictureOutput.saveNextFrameToPath("./test.png", format:.png)

pictureInput.processImage(synchronously: true)

renderWindow.loopWithFunction {Thread.sleep(forTimeInterval: 1.0)}
