//
//  MultiSampleRenderer.swift
//  CelestialObservationViewer
//
//  Created by tanaka.takaaki on 2016/07/02.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import Foundation
import OpenGLES
import QuartzCore
import UIKit

class MultiSampleRenderer: Renderer {
    
    private var context: EAGLContext?
    private var screenScale: CGFloat = 1.0
    
    private var backingWidth: GLint             = 0
    private var backingHeight: GLint            = 0
    private var viewFramebuffer: GLuint         = 0
    private var viewRenderbuffer: GLuint        = 0
    private var multiSampleFramebuffer: GLuint  = 0
    private var multiSampleRenderbuffer: GLuint = 0
    private var depthRenderbuffer: GLuint       = 0
    
    init() {
        self.context = EAGLContext(API: .OpenGLES1)
        
        if !EAGLContext.setCurrentContext(context) {
            assert(false, "failed set current context.")
        }
        
        self.screenScale = UIScreen.mainScreen().scale
    }
    
    deinit {
        destroyFramebuffer()
        context = nil
    }
    
    func willRender() {
        if EAGLContext.currentContext() != context {
            EAGLContext.setCurrentContext(context)
        }
        
        glBindFramebufferOES(GLenum(GL_FRAMEBUFFER_OES), multiSampleFramebuffer)
        glClear(GLenum(GL_COLOR_BUFFER_BIT))
    }
    
    func render() {
        // donothing
    }
    
    func didRender() {
        if UIApplication.sharedApplication().applicationState != .Active { return }
        
        glBindFramebufferOES(GLenum(GL_DRAW_FRAMEBUFFER_APPLE), viewFramebuffer)
        glBindFramebufferOES(GLenum(GL_READ_FRAMEBUFFER_APPLE), multiSampleFramebuffer)
        glResolveMultisampleFramebufferAPPLE()
        
        let discards: [GLenum] = [ GLenum(GL_COLOR_ATTACHMENT0_OES) ]
        glDiscardFramebufferEXT(GLenum(GL_READ_FRAMEBUFFER_APPLE), 1, discards)
        glBindRenderbufferOES(GLenum(GL_RENDERBUFFER_OES), viewRenderbuffer)

        context?.presentRenderbuffer(Int(GL_RENDERBUFFER_OES))
    }
    
    func resizeFromLayer(layer: CAEAGLLayer) -> Bool {
        destroyFramebuffer()
        
        glGenFramebuffersOES(1, &viewFramebuffer)
        glGenRenderbuffersOES(1, &viewRenderbuffer)
        glBindFramebufferOES(GLenum(GL_FRAMEBUFFER_OES), viewFramebuffer)
        glBindRenderbufferOES(GLenum(GL_RENDERBUFFER_OES), viewRenderbuffer)
        
        context?.renderbufferStorage(Int(GL_RENDERBUFFER_OES), fromDrawable: layer)
        
        glFramebufferRenderbufferOES(GLenum(GL_FRAMEBUFFER_OES), GLenum(GL_COLOR_ATTACHMENT0_OES), GLenum(GL_RENDERBUFFER_OES), viewRenderbuffer)
        glGetRenderbufferParameterivOES(GLenum(GL_RENDERBUFFER_OES), GLenum(GL_RENDERBUFFER_WIDTH_OES), &backingWidth)
        glGetRenderbufferParameterivOES(GLenum(GL_RENDERBUFFER_OES), GLenum(GL_RENDERBUFFER_HEIGHT_OES), &backingHeight)
        
        // Multi Sample Anti Aliasing
        glGenFramebuffersOES(1, &multiSampleFramebuffer)
        glGenRenderbuffersOES(1, &multiSampleRenderbuffer)
        glBindFramebufferOES(GLenum(GL_FRAMEBUFFER_OES), multiSampleFramebuffer)
        glBindRenderbufferOES(GLenum(GL_RENDERBUFFER_OES), multiSampleRenderbuffer)
        glRenderbufferStorageMultisampleAPPLE(GLenum(GL_RENDERBUFFER_OES), 4, GLenum(GL_RGB5_A1_OES), backingWidth, backingHeight)
        glFramebufferRenderbufferOES(GLenum(GL_FRAMEBUFFER_OES), GLenum(GL_COLOR_ATTACHMENT0_OES), GLenum(GL_RENDERBUFFER_OES), multiSampleRenderbuffer)

        if glCheckFramebufferStatusOES(GLenum(GL_FRAMEBUFFER_OES)) != GLenum(GL_FRAMEBUFFER_COMPLETE_OES) {
            print("failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GLenum(GL_FRAMEBUFFER_OES)))
            return false
        }
        
        glViewport(0, 0, backingWidth, backingHeight)
        glClearColor(0.0, 0.0, 0.0, 0.0)
        glClear(GLenum(GL_COLOR_BUFFER_BIT))
        
        return true
    }
    
    private func destroyFramebuffer() {
        if viewFramebuffer != 0 {
            glDeleteFramebuffersOES(1, &viewFramebuffer)
            viewFramebuffer = 0
        }
        
        if viewRenderbuffer != 0 {
            glDeleteRenderbuffersOES(1, &viewRenderbuffer)
            viewRenderbuffer = 0
        }
        
        if multiSampleFramebuffer != 0 {
            glDeleteFramebuffersOES(1, &multiSampleFramebuffer)
            multiSampleFramebuffer = 0
        }
        
        if multiSampleRenderbuffer != 0 {
            glDeleteRenderbuffersOES(1, &multiSampleRenderbuffer)
            multiSampleRenderbuffer = 0
        }
        
        if depthRenderbuffer != 0 {
            glDeleteRenderbuffersOES(1, &depthRenderbuffer)
            depthRenderbuffer = 0
        }
    }
}