//
//  GyroCompassScene.swift
//  CelestialObservationViewer
//
//  Created by tanaka.takaaki on 2016/07/02.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import Foundation
import CoreGraphics
import OpenGLES
import UIKit

enum GyroCompassType: Int {
    case Cricle = 0
    case North  = 1
    case East   = 2
    case South  = 3
    case West   = 4
    
    func filename() -> String {
        switch self {
        case .Cricle: return "CompassCricle"
        case .North:  return "CompassNorth"
        case .East:   return "CompassEast"
        case .South:  return "CompassSouth"
        case .West:   return "CompassWest"
        }
    }
}

class GyroCompassScene {
    
    private var name: String = ""
    private var circleTexture: GLuint = 0
    private var northTexture: GLuint  = 0
    private var eastTexture: GLuint   = 0
    private var southTexture: GLuint  = 0
    private var westTexture: GLuint   = 0
    
    init(name: String) {
        self.name = name
        createTexture()
    }
    
    deinit {
        if circleTexture != 0 {
            glDeleteTextures(1, &circleTexture)
            circleTexture = 0
        }
        
        if northTexture != 0 {
            glDeleteTextures(1, &northTexture)
            northTexture = 0
        }
        
        if eastTexture != 0 {
            glDeleteTextures(1, &eastTexture)
            eastTexture = 0
        }
        
        if southTexture != 0 {
            glDeleteTextures(1, &southTexture)
            southTexture = 0
        }
        
        if westTexture != 0 {
            glDeleteTextures(1, &westTexture)
            westTexture = 0
        }
    }
    
    func drawSceneCircle() {
        if circleTexture == 0 {
            assert(false, "circleTexture not found.")
            return
        }
        
        let squareVertices: [GLfloat] = [
            -0.5 * 5.0, -0.5 * 5.0,
             0.5 * 5.0, -0.5 * 5.0,
            -0.5 * 5.0,  0.5 * 5.0,
             0.5 * 5.0,  0.5 * 5.0
        ]
        
        let squareColors: [GLubyte] = [
            255, 255, 255, 255,
            255, 255, 255, 255,
            255, 255, 255, 255,
            255, 255, 255, 255
        ]
        
        let texCoords: [GLfloat] = [
            0,   1.0,
            1.0, 1.0,
            0,   0,
            1.0, 0
        ]
        
        glEnable(GLenum(GL_TEXTURE_2D))
        glBindTexture(GLenum(GL_TEXTURE_2D), circleTexture)
        glVertexPointer(2, GLenum(GL_FLOAT), 0, squareVertices)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glColorPointer(4, GLenum(GL_UNSIGNED_BYTE), 0, squareColors)
        glEnableClientState(GLenum(GL_COLOR_ARRAY))
        glTexCoordPointer(2, GLenum(GL_FLOAT), 0, texCoords)
        glEnableClientState(GLenum(GL_TEXTURE_COORD_ARRAY))
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        glDisableClientState(GLenum(GL_TEXTURE_COORD_ARRAY))
        glDisable(GLenum(GL_TEXTURE_2D))
    }
    
    func drawSceneHeading(angle: GLfloat) {
        var texture: GLuint = 0
        
        if angle >= 330.0 || angle <= 30.0 {
            texture = northTexture
        } else if angle >= 60.0 && angle <= 120.0 {
            texture = eastTexture
        } else if angle >= 150.0 && angle <= 210.0 {
            texture = southTexture
        } else if angle >= 240.0 && angle <= 300.0 {
            texture = westTexture
        }
        
        if texture == 0 {
            assert(false, "texture not found.")
            return
        }
        
        let squareVertices: [GLfloat] = [
            -0.5 * 1.0, -0.5 * 1.0,
             0.5 * 1.0, -0.5 * 1.0,
            -0.5 * 1.0,  0.5 * 1.0,
             0.5 * 1.0,  0.5 * 1.0
        ]
        
        let squareColors: [GLubyte] = [
            255, 255, 255, 255,
            255, 255, 255, 255,
            255, 255, 255, 255,
            255, 255, 255, 255
        ]
        
        let texCoords: [GLfloat] = [
            0,   1.0,
            1.0, 1.0,
            0,   0,
            1.0, 0
        ]
        
        glEnable(GLenum(GL_TEXTURE_2D))
        glBindTexture(GLenum(GL_TEXTURE_2D), texture)
        glVertexPointer(2, GLenum(GL_FLOAT), 0, squareVertices)
        glEnableClientState(GLenum(GL_VERTEX_ARRAY))
        glColorPointer(4, GLenum(GL_UNSIGNED_BYTE), 0, squareColors)
        glEnableClientState(GLenum(GL_COLOR_ARRAY))
        glTexCoordPointer(2, GLenum(GL_FLOAT), 0, texCoords)
        glEnableClientState(GLenum(GL_TEXTURE_COORD_ARRAY))
        glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, 4)
        glDisableClientState(GLenum(GL_TEXTURE_COORD_ARRAY))
        glDisable(GLenum(GL_TEXTURE_2D))
    }
    
    private func createTexture() {
        let types: [GyroCompassType] = [.Cricle, .North, .East, .South, .West]
        
        types.forEach { type in
            guard let image = UIImage(named: type.filename()) else { return }
            
            let imageRef = image.CGImage
            
            if imageRef != nil {
                let width = CGImageGetWidth(imageRef)
                let height = CGImageGetHeight(imageRef)
                
                let imageData = UnsafeMutablePointer<GLubyte>(malloc(width * height * 4))
                let imageContext = CGBitmapContextCreate(imageData, width, height, 8, width * 4, CGImageGetColorSpace(imageRef), CGImageAlphaInfo.PremultipliedLast.rawValue)
                
                CGContextSetBlendMode(imageContext, CGBlendMode.Copy)
                CGContextDrawImage(imageContext, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), imageRef)
                
                switch type {
                case .Cricle:
                    glGenTextures(1, &circleTexture)
                    glBindTexture(GLenum(GL_TEXTURE_2D), circleTexture)
                case .North:
                    glGenTextures(1, &northTexture)
                    glBindTexture(GLenum(GL_TEXTURE_2D), northTexture)
                case .East:
                    glGenTextures(1, &eastTexture)
                    glBindTexture(GLenum(GL_TEXTURE_2D), eastTexture)
                case .South:
                    glGenTextures(1, &southTexture)
                    glBindTexture(GLenum(GL_TEXTURE_2D), southTexture)
                case .West:
                    glGenTextures(1, &westTexture)
                    glBindTexture(GLenum(GL_TEXTURE_2D), westTexture)
                }
                
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_GENERATE_MIPMAP), GL_TRUE)
                glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLfloat(GL_LINEAR))
                glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLfloat(GL_LINEAR_MIPMAP_LINEAR))
                glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), UnsafePointer(imageData))
                free(imageData)
            }
        }
    }
}