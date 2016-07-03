//
//  SceneRenderer.swift
//  CelestialObservationViewer
//
//  Created by tanaka.takaaki on 2016/07/02.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import Foundation
import OpenGLES
import QuartzCore

class SceneRenderer: MultiSampleRenderer {
    
    static private let VIEWPORT_WIDTH: GLfloat  = 1.0
    static private let VIEWPORT_HEIGHT: GLfloat = 1.5
    static private let Z_NEAR: GLfloat          = 3.0
    static private let Z_FAR: GLfloat           = sqrtf(pow(400, 2) + pow(400, 2))
    
    private var deviceOrientationPresenter = DeviceOrientationPresenter()
    private var gyroCompassScene: GyroCompassScene?
    private var astronomicalObservationScene: AstronomicalObservationScene?
    
    private var DRAW_SCREEN_WIDTH = {
        return SceneRenderer.VIEWPORT_WIDTH / SceneRenderer.Z_NEAR
    }
    
    private let DRAW_SCREEN_HEIGHT = {
        return SceneRenderer.VIEWPORT_HEIGHT / SceneRenderer.Z_NEAR
    }
    
    override init() {
        super.init()
        
        gyroCompassScene = GyroCompassScene(name: "compass")
        astronomicalObservationScene = AstronomicalObservationScene(name: "Altair")
        
        deviceOrientationPresenter.didUpdateLocation = { [weak self] location in
            self?.astronomicalObservationScene?.setupFromCoordinate(location.coordinate)
        }
    }
    
    override func render() {
        glLoadIdentity()
        
        // AstronomicalObservation
        glPushMatrix()
        
        glRotatef(GLfloat(deviceOrientationPresenter.yaw), 0.0, 0.0, 1.0)
        glRotatef(GLfloat(deviceOrientationPresenter.pitch), 1.0, 0.0, 0.0)
        
        if let altitudeAngle = astronomicalObservationScene?.altitudeAngle {
            glRotatef(GLfloat(altitudeAngle), 1.0, 0.0, 0.0)
        }
        
        if let hedingAngle = astronomicalObservationScene?.hedingAngle {
            glRotatef(GLfloat(deviceOrientationPresenter.roll - hedingAngle), 0.0, 1.0, 0.0)
        }
        
        glTranslatef(0, 0.0, -15)
        
        astronomicalObservationScene?.drawSceneBillboard()
        
        glPopMatrix()
        
        // GyroCompass
        glPushMatrix()
        let angle = fabs(deviceOrientationPresenter.pitch)
        let z = GLfloat(3.0 + (angle < 30.0 ? 0.0 : ((angle - 30.0) / 10.0)))
        glTranslatef(0, 0.0, -z)
        
        glRotatef(GLfloat(deviceOrientationPresenter.yaw), 0.0, 0.0, 1.0)
        glRotatef(GLfloat(deviceOrientationPresenter.pitch), 1.0, 0.0, 0.0)
        glRotatef(GLfloat(deviceOrientationPresenter.roll), 0.0, 1.0, 0.0)
        glRotatef(90, 1.0, 0.0, 0.0)
        
        
        gyroCompassScene?.drawSceneCircle()
        
        glRotatef(90, -1.0, 0.0, 0.0)
        
        let angles: [GLfloat] = [0.0, 90.0, 180.0, 270.0]
        angles.forEach { headingAngle in
            glPushMatrix()
            
            glRotatef(GLfloat(headingAngle), 0.0, -1.0, 0.0)
            glTranslatef(0, 0.5, -1.5)
            glRotatef(GLfloat(deviceOrientationPresenter.pitch), -1.0, 0.0, 0.0)
            
            gyroCompassScene?.drawSceneHeading(headingAngle)
            
            glPopMatrix()
        }

        glPopMatrix()
    }
    
    override func resizeFromLayer(layer: CAEAGLLayer) -> Bool {
        super.resizeFromLayer(layer)
        
        // Set up the viewing volume and orthographic mode.
        glMatrixMode(GLenum(GL_PROJECTION))
        glLoadIdentity()
        glFrustumf(-SceneRenderer.VIEWPORT_WIDTH, SceneRenderer.VIEWPORT_WIDTH, -SceneRenderer.VIEWPORT_HEIGHT, SceneRenderer.VIEWPORT_HEIGHT, SceneRenderer.Z_NEAR, SceneRenderer.Z_FAR)
        
        // Clear the modelview matrix
        glMatrixMode(GLenum(GL_MODELVIEW))
        glLoadIdentity()
        
        // Set up blending mode
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        
        return true
    }
    
    func start() {
        deviceOrientationPresenter.start()
    }
    
    func stop() {
        deviceOrientationPresenter.stop()
    }
}