//
//  AstronomicalObservationScene.swift
//  CelestialObservationViewer
//
//  Created by tanaka.takaaki on 2016/07/03.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreLocation
import OpenGLES
import UIKit

protocol StarPosition {
    var rightAscension: Double { get }
    var declination: Double { get }
    var name: String { set get }
}

struct Altair: StarPosition {
    // right ascension: 19h50m48s
    var rightAscension = 19.5048 * 1.0467
    // declination: +08°52′12″
    var declination = 8.5212
    
    var name = "Altair"
}

struct Sirius: StarPosition {
    // right ascension: 06h45m01s
    var rightAscension = 6.451 * 1.0467
    // declination: -16°43
    var declination = -16.43
    
    var name = "Sirius"
}

class AstronomicalObservationScene {
    
    private var name: String = ""
    private var billboardTexture: GLuint = 0
    private let starPosition: StarPosition = Altair()
    
    var hedingAngle: Double?
    var altitudeAngle: Double?
    
    init(name: String) {
        self.name = name
        createTexture()
        
        // TODO
        setupFromCoordinate(CLLocationCoordinate2D(latitude: 35.01, longitude: 139.75))
    }
    
    deinit {
        if billboardTexture != 0 {
            glDeleteTextures(1, &billboardTexture)
            billboardTexture = 0
        }
    }
    
    func drawSceneBillboard() {
        
        if hedingAngle == nil && altitudeAngle == nil {
            return
        }
        
        if billboardTexture == 0 {
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
        glBindTexture(GLenum(GL_TEXTURE_2D), billboardTexture)
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
        let size = CGSize(width: 128, height: 128)
        
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, UIColor.clearColor().CGColor)
        CGContextFillRect(context, CGRect(origin: CGPointZero, size: size))
        let backImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let backImageView = UIImageView(image: backImage)
        
        let label = UILabel(frame: CGRect(x: 0, y: 32, width: size.width, height: 64))
        label.text = starPosition.name
        label.backgroundColor = UIColor.clearColor()
        label.textAlignment = .Center
        label.textColor = UIColor.redColor()
        backImageView.addSubview(label)
        
        UIGraphicsBeginImageContextWithOptions(backImageView.frame.size, false, UIScreen.mainScreen().scale)
        
        guard let newContext = UIGraphicsGetCurrentContext() else { return }
        
        backImageView.layer.renderInContext(newContext)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let imageRef = image.CGImage
        
        if imageRef != nil {
            let width = CGImageGetWidth(imageRef)
            let height = CGImageGetHeight(imageRef)
            
            let imageData = UnsafeMutablePointer<GLubyte>(malloc(width * height * 4))
            let imageContext = CGBitmapContextCreate(imageData, width, height, 8, width * 4, CGImageGetColorSpace(imageRef), CGImageAlphaInfo.PremultipliedLast.rawValue)
            
            CGContextSetBlendMode(imageContext, CGBlendMode.Copy)
            CGContextDrawImage(imageContext, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), imageRef)
            
            glGenTextures(1, &billboardTexture)
            glBindTexture(GLenum(GL_TEXTURE_2D), billboardTexture)
            
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_GENERATE_MIPMAP), GL_TRUE)
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLfloat(GL_LINEAR))
            glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLfloat(GL_LINEAR_MIPMAP_LINEAR))
            glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), UnsafePointer(imageData))
            free(imageData)
        }
    }
    
    func setupFromCoordinate(coordinate: CLLocationCoordinate2D) {
        
        // equatorial coordinate system -> horizontal system of coordinates
        
        let date = NSDate()
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        // get greenwich time
        let components = calendar.components([.Year, .Month, .Day, .Hour, .Minute, .Second], fromDate: date)
        
        let year = Double(components.year)
        let month = Double(components.month)
        let day = Double(components.day)
        let hour = Double(components.hour)
        let minute = Double(components.minute)
        
        let Y = components.month <= 2 ? year - 1.0 : year
        let M = components.month <= 2 ? month + 12.0 : month
        let D = day
        
        let time = Int(365.25 * Y) + Int(Y / 400.0) - Int(Y / 100.0) + Int(30.59 * (M - 2)) + Int(D) - 678912
        let MJD = Double(time) + (hour / 24.0 + minute / 1440.0 - 0.375)
        
        let d = 0.671262 + 1.0027379094 * (MJD - 40000.0) + coordinate.longitude / 360.0
        
        // hour angle
        let θG = 24.0 * (d - Double(Int(d)))
        
        let h = θG - starPosition.rightAscension
        let H = 360.0 / 24.0 * h
        
        let sinδ = sin(degreesToRadians(180.0 + starPosition.declination))
        let cosδ = cos(degreesToRadians(180.0 + starPosition.declination))
        let sint = sin(degreesToRadians(H))
        let cost = cos(degreesToRadians(H))
        let sinΦ = sin(degreesToRadians(coordinate.latitude))
        let cosΦ = cos(degreesToRadians(coordinate.latitude))
        
        let sina_sinA = cosδ * sint
        let sina_cosA = -cosΦ * sinδ + sinΦ * cosδ * cost
        
        let A = tan(sina_sinA / sina_cosA)
        
        hedingAngle = radiansToDegrees(A)
        
        let cosa = sinΦ * sinδ + cosΦ * cosδ * cost
        
        altitudeAngle = radiansToDegrees(-cosa)
    }
}
