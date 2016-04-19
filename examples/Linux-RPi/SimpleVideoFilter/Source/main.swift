import GPUImage

// For now, rendering requires the window to be created first
let renderWindow = RPiRenderWindow(width:1280, height:720)
let camera = V4LCamera(size:Size(width:1280.0, height:720.0))
let edgeDetection = SobelEdgeDetection()

camera --> edgeDetection --> renderWindow

var terminate:Int = 0

camera.startCapture()
while (terminate == 0) {
	camera.grabFrame()
}