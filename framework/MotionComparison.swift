//
//  MotionComparison.swift
//  GPUImage
//
//  Created by Filip Bajanik on 3.8.17.
//  Copyright © 2017 Sunset Lake Software LLC. All rights reserved.
//

public class MotionComparison: BasicOperation {
    public var treshold: Float = 0.2 { didSet { uniformSettings["treshold"] = treshold } }
    
    public init(treshold: Float = 0.2) {
        super.init(fragmentShader: MotionComparisonFragmentShader, numberOfInputs: 2)
        
        ({self.treshold = treshold})()
    }
}
