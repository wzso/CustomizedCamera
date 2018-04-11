//
//  CustomizedCameraViewController.swift
//  CutomizedCamera
//
//  Created by Zhishen Wen on 2018/4/11.
//  Copyright © 2018 0xa6a. All rights reserved.
//

import UIKit
import AVFoundation

class CustomizedCameraViewController: UIViewController {
    
    fileprivate let session = AVCaptureSession()
    fileprivate var captureDevice: AVCaptureDevice?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        session.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }
    
    @IBAction func captureButtonClick() {
        if let output = session.outputs.first as? AVCaptureStillImageOutput {
            print(output.connections.first!)
            output.captureStillImageAsynchronously(from: output.connections.first!) {
                guard let buffer = $0 else {
                    print($1?.localizedDescription ?? "")
                    return
                }
                guard let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer) else {
                    return
                }
                guard let image = UIImage(data: data) else {
                    return
                }
                self.imageView.isHidden = false
                self.imageView.image = image
                self.captureButton.isHidden = true
                self.clearButton.isHidden = false
            }
        }
    }
    
    @IBAction func clearButtonClick() {
        self.imageView.isHidden = true
        self.imageView.image = nil
        self.captureButton.isHidden = false
        self.clearButton.isHidden = true
    }
}

fileprivate extension CustomizedCameraViewController {
    func setupCaptureSession() {
        var successful = true
        defer {
            if !successful {
                // log error msg...
                print("error setting capture session")
            }
        }
        
        guard let device = tunedCaptureDevice() else {
            successful = false
            return
        }
        captureDevice = device
        
        // begin configuration
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        // preset
        session.sessionPreset = .photo
        // add input
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                successful = false
                return
            }
        } catch {
            print(error.localizedDescription)
            successful = false
            return
        }
        // add output
        let output = AVCaptureStillImageOutput()
        output.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            successful = false
            return
        }

        // insert preview layer
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
    }
    
    private func tunedCaptureDevice() -> AVCaptureDevice? {
        guard let device = AVCaptureDevice.default(for: .video) else {
            return nil
        }
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            return device
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
