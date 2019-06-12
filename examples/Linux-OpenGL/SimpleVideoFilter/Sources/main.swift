import GPUImage
import GPUImageV4LCamera

// For now, GLUT initialization is done in the render window, so that must come first in sequence
let renderWindow = GLUTRenderWindow(width:1280, height:720, title:"Simple Video Filter")
let camera = V4LCamera(size:Size(width:1280.0, height:720.0))
let edgeDetection = SobelEdgeDetection()

camera --> edgeDetection --> renderWindow

camera.startCapture()
renderWindow.loopWithFunction(camera.grabFrame)
