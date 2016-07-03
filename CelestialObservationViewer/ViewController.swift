//
//  ViewController.swift
//  CelestialObservationViewer
//
//  Created by tanaka.takaaki on 2016/07/02.
//  Copyright © 2016年 tanaka.takaaki. All rights reserved.
//

import AVFoundation
import CoreMotion
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var videoPreviewView: UIView!
    
    private var videoInput: AVCaptureDeviceInput?
    private var session: AVCaptureSession?
    private var stillImageOutput: AVCaptureStillImageOutput?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private var previewView: PreviewView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewView = PreviewView(frame: videoPreviewView.bounds)
        previewView?.contentScaleFactor = UIScreen.mainScreen().scale
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        startCameraCapture()
    }
    
    deinit {
        stopCameraCapture()
    }
    
    private func startCameraCapture() {
        if session == nil {
            session = AVCaptureSession()
            
            session?.sessionPreset = AVCaptureSessionPresetPhoto
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            
            guard let _videoPreviewLayer = videoPreviewLayer else { return }
            
            _videoPreviewLayer.masksToBounds = true

            let bounds = videoPreviewView.bounds
            _videoPreviewLayer.frame = bounds
            _videoPreviewLayer.backgroundColor = UIColor.blackColor().CGColor
            _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            videoPreviewView.layer.addSublayer(_videoPreviewLayer)
            
            let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
            let input = try! AVCaptureDeviceInput(device: device)
            
            session?.addInput(input)
            videoInput = input
            
            let newStillImageOutput = AVCaptureStillImageOutput()
            let outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
            
            newStillImageOutput.outputSettings = outputSettings
            
            stillImageOutput = newStillImageOutput
            
            session?.addOutput(stillImageOutput)
            
            if device.isWhiteBalanceModeSupported(.ContinuousAutoWhiteBalance) {
                try! device.lockForConfiguration()
                
                device.whiteBalanceMode = .ContinuousAutoWhiteBalance
                device.unlockForConfiguration()
            }
            
            if device.isExposureModeSupported(.ContinuousAutoExposure) {
                try! device.lockForConfiguration()
                
                device.exposureMode = .ContinuousAutoExposure
                device.unlockForConfiguration()
            }
        }
        
        if let running = session?.running where running == false {
            session?.startRunning()
        }
        
        guard let pv = previewView else { return }
        
        videoPreviewView.addSubview(pv)
        pv.frame = videoPreviewView.bounds
        pv.start()
    }
    
    private func stopCameraCapture() {
        if let running = session?.running where running {
            session?.stopRunning()
        }
        
        guard let pv = previewView else { return }
        
        pv.removeFromSuperview()
        pv.stop()
    }
    
}

