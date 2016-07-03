//
//  OpenGLView.swift
//  CelestialObservationViewer
//
//  Created by tanaka.takaaki on 2016/07/02.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

protocol Renderer {
    func willRender()
    func didRender()
    func render()
    func resizeFromLayer(layer: CAEAGLLayer) -> Bool
}

class OpenGLView: UIView {
    
    private var animating: Bool = false
    private var animationFrameInterval = 1
    private var displayLinkSupported = false
    
    internal var renderer: Renderer?
    
    private var displayLink: CADisplayLink? {
        willSet {
            if displayLink != nil {
                displayLink?.invalidate()
            }
        }
    }
    
    private var animationTimer: NSTimer? {
        willSet {
            if animationTimer != nil {
                animationTimer?.invalidate()
            }
        }
    }
    
    override class func layerClass() -> AnyClass {
        return CAEAGLLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        guard let eaglLayer = self.layer as? CAEAGLLayer else { return }
        eaglLayer.opaque = false
        
        eaglLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking : (false), kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8]
        eaglLayer.contentsScale = UIScreen.mainScreen().scale
        
        let reqSysVer = "3.1"
        let currSysVer = UIDevice.currentDevice().systemVersion
        
        if currSysVer.compare(reqSysVer, options: .NumericSearch) != .OrderedAscending {
            displayLinkSupported = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        renderer = nil
        displayLink = nil
        animationTimer = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let _layer = layer as? CAEAGLLayer {
            renderer?.resizeFromLayer(_layer)
        }
        
        drawView(nil)
    }
    
    /**
     draw view
     */
    func drawView(sender: AnyObject?) {
        if renderer != nil {
            renderer?.willRender()
            renderer?.render()
            renderer?.didRender()
        }
    }
    
    /**
     start animation
     */
    func startAnimation() {
        if !animating {
            if displayLinkSupported {
                displayLink = CADisplayLink(target: self, selector: #selector(drawView(_:)))
                displayLink?.frameInterval = animationFrameInterval
                displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
            } else {
                animationTimer = NSTimer(timeInterval: ((1.0 / 60.0) * Double(animationFrameInterval)), target: self, selector: #selector(drawView(_:)), userInfo: nil, repeats: true)
            }
            animating = true
        }
    }
    
    /**
     stop animation
     */
    func stopAnimation() {
        if animating {
            if displayLinkSupported {
                displayLink = nil
            } else {
                animationTimer = nil
            }
            animating = false
        }
    }
}
