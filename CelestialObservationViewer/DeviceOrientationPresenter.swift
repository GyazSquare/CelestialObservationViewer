//
//  DeviceOrientationPresenter.swift
//  CelestialObservationViewer
//
//  Created by tanaka.takaaki on 2016/07/02.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import CoreLocation
import CoreMotion
import Foundation
import UIKit

func degreesToRadians(angle: Double) -> Double {
    return angle / 180.0 * M_PI
}

func radiansToDegrees(angle: Double) -> Double {
    return angle * (180.0 / M_PI)
}

class DeviceOrientationPresenter: NSObject {
    static private let UpdateFrequency = 30.0
    static private let TransitionDelay = 0.5
    
    private var DT: Double {
        return 1.0 / DeviceOrientationPresenter.UpdateFrequency
    }
    
    var didUpdateLocation: ((CLLocation) -> (Void))?
    
    private var location = CLLocation(latitude: kCLLocationCoordinate2DInvalid.latitude, longitude: kCLLocationCoordinate2DInvalid.longitude)
    
    private var motionManager: CMMotionManager?
    private var locationManager: CLLocationManager?
    
    private let deviceMotionQueue = NSOperationQueue()
    private let lowpassFilter: LowpassFilter = LowpassFilter(sampleRate: DeviceOrientationPresenter.UpdateFrequency, cutoffFrequency: 5.0)
    
    private var bpx: Double = 0.0
    private var bpy: Double = 0.0
    private var bpz: Double = 0.0
    
    private var magneticHeading: Double = -1.0
    private var trueHeading: Double = -1.0
    
    var roll: Double = 0.0
    var pitch: Double = 0.0
    var yaw: Double = 0.0
    
    private var deviceAngle = 0.0
    private var deviceOrientation: UIDeviceOrientation = .Portrait
    
    func start() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.distanceFilter = 5
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.headingFilter = kCLHeadingFilterNone
        
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .NotDetermined:
                locationManager?.requestAlwaysAuthorization()
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                locationManager?.startUpdatingLocation()
            case .Denied, .Restricted:
                ()
            }
        }
        
        if CLLocationManager.headingAvailable() {
            locationManager?.startUpdatingHeading()
        }
        
        motionManager = CMMotionManager()
        motionManager?.accelerometerUpdateInterval = 1.0 / DeviceOrientationPresenter.UpdateFrequency
        motionManager?.deviceMotionUpdateInterval = 1.0 / DeviceOrientationPresenter.UpdateFrequency
        
        let enableGyro = motionManager?.deviceMotionAvailable
        
        if let gyro = enableGyro where gyro {
            motionManager?.startDeviceMotionUpdatesToQueue(deviceMotionQueue, withHandler: { [weak self] deviceMotion, error in
                guard let `self` = self else { return }
                guard let motion = deviceMotion else { return }
                
                let accelerationX = motion.gravity.x
                let accelerationY = motion.gravity.y
                let accelerationZ = motion.gravity.z
                
                self.lowpassFilter.addAcceleration(x: accelerationX, y: accelerationY, z: accelerationZ)
                self.deviceOrientationUpdate()
                
                // yaw
                var angle = radiansToDegrees(atan2(accelerationX, -accelerationY))
                
                while true {
                    let gap = self.yaw - angle
                    if (gap > 180.0) {
                        angle += 360.0
                    } else if (gap <= -180.0) {
                        angle -= 360.0
                    } else {
                        break
                    }
                }
                
                self.yaw = (0.94 * (self.yaw + radiansToDegrees(-motion.rotationRate.z) * self.DT)) + (0.06 * angle)
                
                // pitch
                let g = sqrt(pow(accelerationX, 2) + pow(accelerationY, 2) + pow(accelerationZ, 2))
                var slope = -(radiansToDegrees(asin(accelerationZ / g)))
                let pitch = (motion.rotationRate.x * cos(degreesToRadians(self.yaw))) + (motion.rotationRate.y * sin(degreesToRadians(self.yaw)))
                while true {
                    let gap = self.pitch - slope
                    if gap > 180.0 {
                        slope += 360.0
                    } else if gap <= -180.0 {
                        slope -= 360.0
                    } else {
                        break
                    }
                }
                self.pitch = (0.94 * (self.pitch + radiansToDegrees(-pitch) * self.DT)) + (0.06 * slope)
                
                // roll
                var heading = self.trueHeading
                
                let roll = (motion.rotationRate.x * -sin(degreesToRadians(self.yaw))) + (motion.rotationRate.y * cos(degreesToRadians(self.yaw)))
                while true {
                    let gap = self.roll - heading
                    if gap > 180.0 {
                        heading += 360.0
                    } else if gap <= -180.0 {
                        heading -= 360.0
                    } else {
                        break
                    }
                }
                self.roll = (0.98 * (self.roll + radiansToDegrees(-roll) * self.DT)) + (0.02 * heading)
            })
        } else {
            if let available = motionManager?.accelerometerAvailable where available {
                motionManager?.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue()!, withHandler: { [weak self] accelerometerData, error in
                    guard let `self` = self else { return }
                    guard let data = accelerometerData else { return }
                    
                    let accelerationX = data.acceleration.x
                    let accelerationY = data.acceleration.y
                    let accelerationZ = data.acceleration.z
                    
                    self.lowpassFilter.addAcceleration(x: accelerationX, y: accelerationY, z: accelerationZ)
                    self.deviceOrientationUpdate()
                    
                    let g = sqrt(pow(self.lowpassFilter.x, 2) + pow(self.lowpassFilter.y, 2) + pow(self.lowpassFilter.z, 2))
                    let slope = -(radiansToDegrees(asin(self.lowpassFilter.z / g)))
                    let angle = radiansToDegrees(atan2(-self.lowpassFilter.x, self.lowpassFilter.y) + M_PI)
                    
                    self.pitch = slope
                    self.yaw = angle
                    self.roll = self.trueHeading
                })
            }
        }
    }
    
    func stop() {
        locationManager?.stopUpdatingLocation()
        locationManager?.stopUpdatingHeading()
        locationManager = nil
        
        if let available = motionManager?.deviceMotionAvailable where available {
            motionManager?.stopDeviceMotionUpdates()
        } else {
            if let available = motionManager?.accelerometerAvailable where available {
                motionManager?.stopAccelerometerUpdates()
            }
        }
        motionManager = nil
    }
    
    private func deviceOrientationUpdate() {
        let x = lowpassFilter.x
        let y = lowpassFilter.y
        
        let angle = atan2(-x , y)
        deviceAngle = radiansToDegrees(angle + M_PI)
        if deviceAngle >= 330 || deviceAngle <= 30 {
            deviceOrientation = .Portrait
        } else if deviceAngle >= 60 && deviceAngle <= 120 {
            deviceOrientation = .LandscapeRight
        } else if deviceAngle >= 150 && deviceAngle <= 210 {
            deviceOrientation = .PortraitUpsideDown
        } else if deviceAngle >= 240 && deviceAngle <= 300 {
            deviceOrientation = .LandscapeLeft
        }
    }
    
}

// MARK: - CLLocationManagerDelegate
extension DeviceOrientationPresenter: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        if CLLocationCoordinate2DIsValid(newLocation.coordinate) { return }
        
        let howRecent = newLocation.timestamp.timeIntervalSinceNow
        
        if abs(howRecent) < 15.0 {
            location = newLocation
            didUpdateLocation?(location)
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy > 0 {
            
            guard let _motionManager = motionManager else { return }
            
            let enableGyro = _motionManager.deviceMotionAvailable
            // use the NED (North, East, Down) coordinate system
            // gp: phone accelerometer value
            var gpx = 0.0
            var gpy = 0.0
            var gpz = 0.0
            
            if let motion = _motionManager.deviceMotion where enableGyro {
                gpx = -motion.gravity.z
                gpy =  motion.gravity.x
                gpz = -motion.gravity.y
            } else {
                gpx = -lowpassFilter.z
                gpy =  lowpassFilter.x
                gpz = -lowpassFilter.y
            }
            
            // bp: phone magnetometer value
            if enableGyro {
                bpx = -newHeading.z
                bpy =  newHeading.x
                bpz = -newHeading.y
            } else {
                let _bpx = -newHeading.z
                let _bpy =  newHeading.x
                let _bpz = -newHeading.y
                let alpha = 0.1
                bpx = _bpx * alpha + bpx * (1.0 - alpha)
                bpy = _bpy * alpha + bpy * (1.0 - alpha)
                bpz = _bpz * alpha + bpz * (1.0 - alpha)
            }
            
            // calculate Roll (phi) and Pitch (theta)
            let phi = atan2(gpy, gpz)
            let theta = atan2(-gpx, (gpy * sin(phi)) + (gpz * cos(phi)))
            let bfy = (bpy * cos(phi)) - (bpz * sin(phi))
            let bfx = (bpx * cos(theta)) + (bpy * sin(theta) * sin(phi)) + (bpz * sin(theta) * cos(phi))
            
            // calculate Yaw (psi)
            let psi = atan2(-bfy, bfx)
            let _magneticHeading = psi / M_PI * 180.0
            var magneticDeclination = newHeading.trueHeading < 0.0 ? 0.0 : newHeading.trueHeading - newHeading.magneticHeading
            if magneticDeclination > 180.0 {
                magneticDeclination -= 360.0
            }
            let _trueHeading = _magneticHeading + magneticDeclination
            
            magneticHeading = (_magneticHeading < 0.0) ? (_magneticHeading + 360.0) : _magneticHeading
            
            trueHeading = enableGyro ? _trueHeading : ((_trueHeading < 0.0) ? (_trueHeading + 360.0) : _trueHeading)
        }
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager) -> Bool {
        return true
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .NotDetermined:
            ()
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            locationManager?.startUpdatingLocation()
        case .Denied, .Restricted:
            ()
        }
    }
    
}