//
//  PreviewView.swift
//  CelestialObservationViewer
//
//  Created by tanaka.takaaki on 2016/07/02.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import Foundation
import UIKit

class PreviewView: OpenGLView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.renderer = SceneRenderer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func start() {
        guard let renderer = renderer as? SceneRenderer else { return }
        
        renderer.start()
        startAnimation()
    }
    
    func stop() {
        guard let renderer = renderer as? SceneRenderer else { return }
        
        renderer.stop()
        stopAnimation()
    }
}