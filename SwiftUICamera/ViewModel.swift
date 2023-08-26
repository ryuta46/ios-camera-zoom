//
//  ViewModel.swift
//  SwiftUICamera
//  
//  Created by ryuta46 on 2023/04/10.
//  
//

import UIKit
import Combine
import AVFoundation

class ViewModel: NSObject, ObservableObject {
    @Published var image: UIImage?
    @Published var imageAspectRatio: CGFloat?

    @Published var errorText: String = ""

    @Published var standardZoomFactor: CGFloat = 1.0

    @Published var minFactor: CGFloat = 1.0
    @Published var maxFactor: CGFloat = 10.0



    @Published var linearZoomFactor: Float = 1.0 {
        didSet {
            zoom(linearFactor: linearZoomFactor)
        }
    }

    ///プレビュー用レイヤー
    var previewLayer: CALayer?

    private var capturesImage = false
    private let captureSession = AVCaptureSession()
    private var device: AVCaptureDevice?

    override init() {
        super.init()

        prepareCamera()
        configureSession()
    }

    func captureImageOnce() {
        capturesImage = true
    }

    private func prepareCamera() {
        captureSession.sessionPreset = .photo

        let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera]
        let mediaType: AVMediaType =  .video

        device = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: mediaType, position: .back).devices.first

        if let device {
            print("Zoom Factor Range: \(device.minAvailableVideoZoomFactor) - \(device.maxAvailableVideoZoomFactor)")
            print("Zoom Factor Switch: \(device.virtualDeviceSwitchOverVideoZoomFactors)")

            for actualDevice in device.constituentDevices {
                print("Candidate: \(actualDevice.localizedName) \(actualDevice.deviceType)")
            }

            standardZoomFactor = 1
            for (index, actualDevice) in device.constituentDevices.enumerated() {
                if (actualDevice.deviceType != .builtInUltraWideCamera) {
                    if index > 0 && index <= device.virtualDeviceSwitchOverVideoZoomFactors.count {
                        standardZoomFactor = CGFloat(truncating: device.virtualDeviceSwitchOverVideoZoomFactors[index - 1])
                    }
                    break
                }
            }
            minFactor = device.minAvailableVideoZoomFactor
            maxFactor = min(device.maxAvailableVideoZoomFactor, 15.0)
        } else {
            errorText = "No available device"
        }

    }

    private func configureSession() {
        guard let device else {
            return
        }
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: device)

            captureSession.addInput(captureDeviceInput)
        } catch {
            errorText = error.localizedDescription
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = previewLayer

        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]

        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }

        captureSession.commitConfiguration()

        let queue = DispatchQueue(label: "videoqueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
    }

    func startSession() {
        guard !captureSession.isRunning else {
            return
        }
        DispatchQueue.global(qos: .default).async {
            self.captureSession.startRunning()

            DispatchQueue.main.async {
                self.linearZoomFactor = Float(self.standardZoomFactor)
            }
        }

    }

    func endSession() {
        guard captureSession.isRunning else {
            return
        }
        DispatchQueue.global(qos: .default).async {
            self.captureSession.stopRunning()
        }
    }

    func zoom(linearFactor: Float) {
        guard let device else {
            return
        }

        do {
            try device.lockForConfiguration()
            device.cancelVideoZoomRamp()
            device.ramp(toVideoZoomFactor: CGFloat(linearFactor), withRate: 10)
            device.unlockForConfiguration()
        }  catch {
            errorText = error.localizedDescription
        }
    }

}


extension ViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if imageAspectRatio == nil {
            updateImageAspectRatio(buffer: sampleBuffer)
        }
        guard capturesImage else {
            return
        }
        if let image = getImageFromSampleBuffer(buffer: sampleBuffer) {
            DispatchQueue.main.async {
                self.image = image
            }
        }
        capturesImage = false
    }

    private func updateImageAspectRatio(buffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return
        }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        DispatchQueue.main.async {
            self.imageAspectRatio = CGFloat(height) / CGFloat(width)
        }
    }

    private func getImageFromSampleBuffer(buffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return nil
        }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()

        let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))

        guard let image = context.createCGImage(ciImage, from: imageRect) else {
            return nil
        }
        return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
    }
}
