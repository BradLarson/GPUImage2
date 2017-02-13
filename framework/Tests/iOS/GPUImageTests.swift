//
//  GPUImageTests.swift
//  GPUImageTests
//
//  Created by Brad Larson on 2/6/2016.
//  Copyright © 2016 Sunset Lake Software LLC. All rights reserved.
//

import XCTest
@testable import GPUImage
import AVFoundation

class GPUImageTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testCameraError() {
        if ( PhysicalCameraLocation.BackFacing.device() == nil && PhysicalCameraLocation.FrontFacing.device() == nil) {
            do {
                let camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
                XCTFail("Camera():\(camera) should throw error on Simulator")
            } catch {
                XCTAssert(error is CameraError, "Exception should be CameraError")
            }
        } else {
            XCTAssert(true, "Untestable condition: camera available")
        }
    }
    
}
