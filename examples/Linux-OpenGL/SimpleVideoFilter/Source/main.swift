import GPUImage

let camera = V4LCamera(size:Size(width:1280.0, height:720.0))
let renderWindow = GLUTRenderWindow(width:1280, height:720, title:"Simple Video Filter")
let edgeDetection = SobelEdgeDetection()

camera --> edgeDetection --> renderWindow

camera.startCapture()
renderWindow.loopWithFunction(camera.grabFrame)