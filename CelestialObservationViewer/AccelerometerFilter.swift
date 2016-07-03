//
//  AccelerometerFilter.swift
//  CelestialObservationViewer
//
//  Created by tanaka.takaaki on 2016/07/02.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import CoreFoundation
import UIKit

func Norm(x x: Double, y: Double, z: Double) -> Double {
    return sqrt(x * x + y * y + z * z)
}

func Clamp(v v: Double, min: Double, max: Double) -> Double {
    if v > max {
        return max
    } else if v < min {
        return min
    } else {
        return v
    }
}

class AccelerometerFilter {
    
    var adaptive: Bool = false
    
    var x: UIAccelerationValue = 0.0
    var y: UIAccelerationValue = 0.0
    var z: UIAccelerationValue = 0.0
    
    func addAcceleration(accel: Double) {
        addAcceleration(x: accel, y: accel, z: accel)
    }
    
    func addAcceleration(x x: UIAccelerationValue, y: UIAccelerationValue, z: UIAccelerationValue) {
        self.x = x
        self.y = y
        self.z = z
    }
    
}

class LowpassFilter: AccelerometerFilter {
    
    private let AccelerometerMinStep = 0.02
    private let AccelerometerNoiseAttenuation = 3.0
    
    private var filterConstant: Double = 0.0
    
    init(sampleRate rate: Double, cutoffFrequency freq: Double) {
        let dt = 1.0 / rate
        let RC = 1.0 / freq
        self.filterConstant = RC / (dt + RC)
    }
    
    override func addAcceleration(x x: UIAccelerationValue, y: UIAccelerationValue, z: UIAccelerationValue) {
        var alpha = filterConstant
        
        if adaptive {
            let v = fabs(Norm(x: self.x, y: self.y, z: self.z) - Norm(x: x, y: y, z: z)) / AccelerometerMinStep - 1.0
            let d = Clamp(v: v, min: 0.0, max: 1.0)
            alpha = (1.0 - d) * filterConstant / AccelerometerNoiseAttenuation + d * filterConstant
        }
        
        self.x = x * alpha + self.x * (1.0 - alpha)
        self.y = y * alpha + self.y * (1.0 - alpha)
        self.z = z * alpha + self.z * (1.0 - alpha)
    }
}

class HighpassFilter: AccelerometerFilter {
    
    private let AccelerometerMinStep = 0.02
    private let AccelerometerNoiseAttenuation = 3.0
    
    private var filterConstant: Double = 0.0
    
    private var lastX: UIAccelerationValue = 0.0
    private var lastY: UIAccelerationValue = 0.0
    private var lastZ: UIAccelerationValue = 0.0
    
    init(sampleRate rate: Double, cutoffFrequency freq: Double) {
        let dt = 1.0 / rate
        let RC = 1.0 / freq
        self.filterConstant = RC / (dt + RC)
    }
    
    override func addAcceleration(x x: UIAccelerationValue, y: UIAccelerationValue, z: UIAccelerationValue) {
        var alpha = filterConstant
        
        if adaptive {
            let v = fabs(Norm(x: self.x, y: self.y, z: self.z) - Norm(x: x, y: y, z: z)) / AccelerometerMinStep - 1.0
            let d = Clamp(v: v, min: 0.0, max: 1.0)
            alpha = d * filterConstant / AccelerometerNoiseAttenuation + (1.0 - d) * filterConstant
        }
        
        self.x = alpha * (self.x + x - lastX)
        self.y = alpha * (self.y + y - lastY)
        self.z = alpha * (self.z + z - lastZ)
        
        lastX = x
        lastY = y
        lastZ = z
    }
}
