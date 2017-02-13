import XCTest
//@testable import GPUImage

class FakeOperation: ImageProcessingOperation {
    let targets = TargetContainer()
    let sources = SourceContainer()
    var maximumInputs:UInt { get { return 1 } } // Computed property, so it can be overridden
    let name:String
    
    init(name:String) {
        self.name = name
    }
    
    func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
    }

    func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
    }
}

class FakeRenderView: ImageConsumer {
    let sources = SourceContainer()
    let maximumInputs:UInt = 1
    
    func newFramebufferAvailable(_ framebuffer:Framebuffer, fromSourceIndex:UInt) {
    }
}

class FakeCamera: ImageSource {
    let targets = TargetContainer()
    
    func transmitPreviousImage(to target:ImageConsumer, atIndex:UInt) {
    }
    
    func newCameraFrame() {
        // Framebuffer has size, orientation encoded in it
        
//        for target in targets {
//            target.newFramebufferAvailable(cameraFramebuffer, fromProducer:self)
//        }
    }
    
    func startCameraCapture() {
        self.newCameraFrame()
    }
}

class Pipeline_Tests: XCTestCase {
    
    func testTargetContainer() {
        let targetContainer = TargetContainer()
        
        // All operations have been added and should have a strong reference
        var operation1:FakeOperation? = FakeOperation(name:"Operation 1")
        targetContainer.append(operation1!, indexAtTarget:0)
        var operation2:FakeOperation? = FakeOperation(name:"Operation 2")
        targetContainer.append(operation2!, indexAtTarget:0)
        var operation3:FakeOperation? = FakeOperation(name:"Operation 3")
        targetContainer.append(operation3!, indexAtTarget:0)
        var operation4:FakeOperation? = FakeOperation(name:"Operation 4")
        targetContainer.append(operation4!, indexAtTarget:0)

        for (index, (target, _)) in targetContainer.enumerated() {
            let operation = target as! FakeOperation
            switch index {
                case 0: XCTAssert(operation.name == "Operation 1")
                case 1: XCTAssert(operation.name == "Operation 2")
                case 2: XCTAssert(operation.name == "Operation 3")
                case 3: XCTAssert(operation.name == "Operation 4")
                default: XCTFail("Should not have hit an index this high")
            }
        }
        
        // Strong references have gone away, therefore the weak references should now be nil in the container
        operation2 = nil
        operation4 = nil

        for (index, (target, _)) in targetContainer.enumerated() {
            let operation = target as! FakeOperation
            switch index {
                case 0: XCTAssert(operation.name == "Operation 1")
                case 1: XCTAssert(operation.name == "Operation 3")
                default: XCTFail("Should not have hit an index this high")
            }
        }

        operation1 = nil
        
        for (index, (target, _)) in targetContainer.enumerated() {
            let operation = target as! FakeOperation
            switch index {
                case 0: XCTAssert(operation.name == "Operation 3")
                default: XCTFail("Should not have hit an index this high")
            }
        }

        operation3 = nil
        for (_, (_, _)) in targetContainer.enumerated() {
            XCTFail("Should not be any targets left in the container")
        }
    }
    
    func testSourceContainer() {
        
    }
    
    func testChaining() {
//        let camera = FakeCamera()
//        let filter = FakeOperation(name:"TestOperation")
//        let view = FakeRenderView()
//        
//        camera --> filter --> view
//        camera.startCameraCapture()
        
        // Test removal of scope on camera setup
    }
    
}
