//
//  BarcodeScannerView.swift
//  BarcodeScannerApp
//
//  Created by OpenAI Assistant on 11/29/24.
//

import SwiftUI
import Vision
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

class BarcodeScannerUIViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
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

        setupCaptureSession()
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .hd4K3840x2160 // High resolution for small details
        print("Capture session set to 4K resolution.")

        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            print("Failed to access camera.")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if let captureSession = captureSession, captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }

            // Configure zoom and focus
            try videoDevice.lockForConfiguration()
            let desiredZoomFactor: CGFloat = 1.2
            if desiredZoomFactor <= videoDevice.activeFormat.videoMaxZoomFactor {
                videoDevice.videoZoomFactor = desiredZoomFactor
                print("Zoom set to \(desiredZoomFactor)x.")
            }
            if videoDevice.isSmoothAutoFocusSupported {
                videoDevice.isSmoothAutoFocusEnabled = true
                print("Smooth auto-focus enabled.")
            }
            videoDevice.unlockForConfiguration()

        } catch {
            print("Error setting up video input: \(error.localizedDescription)")
            return
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "barcodeScannerQueue"))
        if let captureSession = captureSession, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
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

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectBarcodesRequest { request, error in
            if let error = error {
                print("Error detecting barcodes: \(error.localizedDescription)")
                return
            }

            guard let results = request.results as? [VNBarcodeObservation] else { return }

            DispatchQueue.main.async {
                for result in results {
                    if let payload = result.payloadStringValue {
                        self.handleDetectedBarcode(payload: payload, bounds: result.boundingBox)
                    }
                }
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    private func handleDetectedBarcode(payload: String, bounds: CGRect) {
        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastProcessedTime > cooldownPeriod else {
            return // Skip processing if within cooldown period
        }
        lastProcessedTime = currentTime

        let normalizedValue = payload.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedSerials = serialNumbers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let isMatched = normalizedSerials.contains(normalizedValue)

        print("Checking if matched: \(normalizedValue) in \(normalizedSerials) -> \(isMatched)")

        if isMatched {
            print("Matched serial number: \(payload)")
            highlightBarcode(bounds: bounds)
            triggerHapticFeedback()
        } else {
            print("Scanned value: \(payload) did not match any serial numbers.")
        }

        onScanned?(payload)
    }

    private func highlightBarcode(bounds: CGRect) {
        guard let previewLayer = previewLayer else { return }

        // Convert Vision's normalized bounding box to previewLayer coordinates
        let convertedBounds = previewLayer.layerRectConverted(fromMetadataOutputRect: bounds)

        DispatchQueue.main.async {
            self.highlightView.frame = convertedBounds
            self.view.bringSubviewToFront(self.highlightView)

            // Add pulse animation to the highlight
            UIView.animate(
                withDuration: 0.2,
                animations: {
                    self.highlightView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                },
                completion: { _ in
                    UIView.animate(
                        withDuration: 0.2,
                        animations: {
                            self.highlightView.transform = .identity
                        },
                        completion: { _ in
                            // Clear the highlight after the animation is done
                            self.highlightView.frame = .zero
                        }
                    )
                }
            )

            print("Updated highlight frame to: \(convertedBounds)")
        }
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
