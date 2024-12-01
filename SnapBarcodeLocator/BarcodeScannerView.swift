//
//  BarcodeScannerView.swift
//  BarcodeScannerApp
//
//  Created by OpenAI Assistant on 11/29/24.
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var serialNumbers: [String]
    var onScanned: (String) -> Void // Closure to handle all scanned barcodes

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned, serialNumbers: $serialNumbers)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = BarcodeScannerUIViewController()
        viewController.updateSerialNumbers(serialNumbers) // Initialize serial numbers
        viewController.onScanned = onScanned
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let scannerVC = uiViewController as? BarcodeScannerUIViewController {
            scannerVC.updateSerialNumbers(serialNumbers) // Keep serial numbers in sync
        }
    }

    class BarcodeScannerUIViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        private var serialNumbers: [String] = []
        var onScanned: ((String) -> Void)?
        private var captureSession: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private var highlightView: UIView = {
            let view = UIView()
            view.layer.borderColor = UIColor.green.cgColor
            view.layer.borderWidth = 2
            view.backgroundColor = UIColor.clear
            return view
        }()

        private var lastProcessedTime: TimeInterval = 0
        private let cooldownPeriod: TimeInterval = 0.5 // 500ms cooldown

        func updateSerialNumbers(_ serialNumbers: [String]) {
            self.serialNumbers = serialNumbers
            print("Updated serial numbers: \(serialNumbers)")
        }


        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black

            captureSession = AVCaptureSession()

            // Set high-resolution preset
            captureSession?.sessionPreset = .hd4K3840x2160 // High resolution for small details
            print("Capture session set to 4K resolution.")

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                print("Failed to access camera.")
                return
            }

            do {
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                if let captureSession = captureSession, captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                }

                // Configure dynamic zoom and macro focus
                try videoCaptureDevice.lockForConfiguration()

                let desiredZoomFactor: CGFloat = 1.2 // Adjust as needed

                if desiredZoomFactor <= videoCaptureDevice.activeFormat.videoMaxZoomFactor {
                    videoCaptureDevice.videoZoomFactor = desiredZoomFactor
                    print("Zoom set to \(desiredZoomFactor)x.")
                } else {
                    print("Desired zoom factor \(desiredZoomFactor)x exceeds the maximum supported zoom factor: \(videoCaptureDevice.activeFormat.videoMaxZoomFactor).")
                }

                // Macro focus settings
                if videoCaptureDevice.isSmoothAutoFocusSupported {
                    videoCaptureDevice.isSmoothAutoFocusEnabled = true
                    print("Smooth auto-focus enabled.")
                }

                videoCaptureDevice.unlockForConfiguration()

            } catch {
                print("Error setting up video input: \(error.localizedDescription)")
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if let captureSession = captureSession, captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [
                    .ean8, .ean13, .code128, .qr,
                    .pdf417, .code39, .code39Mod43, .code93,
                    .aztec, .dataMatrix, .interleaved2of5, .itf14
                ]
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer?.frame = view.layer.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }

            view.addSubview(highlightView)
            view.bringSubviewToFront(highlightView)

            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
            }
        }


        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let readableObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let stringValue = readableObject.stringValue,
                let previewLayer = previewLayer else { return }

            let currentTime = Date().timeIntervalSince1970
            guard currentTime - lastProcessedTime > cooldownPeriod else {
                return // Skip processing if within cooldown period
            }
            lastProcessedTime = currentTime

            DispatchQueue.main.async {
                // Normalize both the scanned value and the serial numbers for comparison
                let normalizedValue = stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let normalizedSerials = self.serialNumbers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

                let isMatched = normalizedSerials.contains(normalizedValue)
                print("Checking if matched: \(normalizedValue) in \(normalizedSerials) -> \(isMatched)")

                if isMatched {
                    print("Matched serial number: \(stringValue)")

                    // Highlight the barcode with a bounding box
                    if let barcodeBounds = previewLayer.transformedMetadataObject(for: readableObject)?.bounds {
                        self.highlightView.frame = barcodeBounds
                        self.view.bringSubviewToFront(self.highlightView)
                        print("Highlight frame set to: \(barcodeBounds)")

                        // Add pulse animation
                        UIView.animate(withDuration: 0.2,
                                    animations: {
                                        self.highlightView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                                    },
                                    completion: { _ in
                                        UIView.animate(withDuration: 0.2, animations: {
                                            self.highlightView.transform = .identity
                                        })
                                    })
                    } else {
                        print("Failed to transform metadata bounds for barcode: \(stringValue)")
                    }

                    // Trigger haptics
                    self.triggerHapticFeedback()

                    // Pause scanning for 1 second to let the highlight persist
                    self.pauseScanning(for: 1.0)
                } else {
                    print("Scanned value: \(stringValue) did not match any serial numbers.")
                }

                // Add the scanned barcode to the list
                self.onScanned?(stringValue)
            }
        }

        private func pauseScanning(for duration: TimeInterval) {
            captureSession?.stopRunning()

            print("Pausing")
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + duration) {
                self.captureSession?.startRunning()

                // Since UI updates (like clearing the highlight frame) must happen on the main thread,
                // we move this part back to the main queue.
                DispatchQueue.main.async {
                    self.highlightView.frame = .zero // Clear highlight after the pause
                }
            }


            // DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            //     self.captureSession?.startRunning()
            //     self.highlightView.frame = .zero // Clear highlight after the pause
            // }
        }

        private func triggerHapticFeedback() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            print("Haptics triggered.")
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            captureSession?.stopRunning()
        }
    }

    class Coordinator: NSObject {
        var onScanned: (String) -> Void
        @Binding var serialNumbers: [String]

        init(onScanned: @escaping (String) -> Void, serialNumbers: Binding<[String]>) {
            self.onScanned = onScanned
            _serialNumbers = serialNumbers
        }
    }
}
