import GPUImage

let camera = V4LCamera(size:Size(width:1280.0, height:720.0))
let renderWindow = RPiRenderWindow(width:1280, height:720)
let edgeDetection = SobelEdgeDetection()

camera --> edgeDetection --> renderWindow

var terminate:Int = 0

camera.startCapture()
while (terminate == 0) {
	camera.grabFrame()
}