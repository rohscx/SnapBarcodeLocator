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
    var onVisionReady: ((Bool) -> Void)? // Add a callback for Vision readiness

    func makeCoordinator() -> Coordinator {
        Coordinator(onScanned: onScanned, serialNumbers: $serialNumbers)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = BarcodeScannerUIViewController()
        viewController.updateSerialNumbers(serialNumbers) // Initialize serial numbers
        viewController.onScanned = onScanned
        viewController.onVisionReady = onVisionReady // Pass the readiness callback
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
        var onVisionReady: ((Bool) -> Void)? // Vision readiness callback
        private var captureSession: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        private var highlightView: UIView = {
            let view = UIView()
            view.layer.borderColor = UIColor.green.cgColor
            view.layer.borderWidth = 2
            view.backgroundColor = UIColor.clear
            return view
        }()
        private var isFeedbackViewAdded = false


        private var loadingLabel: UILabel! // Loading label for feedback
        private var activityIndicator: UIActivityIndicatorView! // Activity indicator for feedback
        private var visionReady = false // Tracks Vision initialization state

        private var lastProcessedTime: TimeInterval = 0
        private let cooldownPeriod: TimeInterval = 0.5 // 500ms cooldown

        func updateSerialNumbers(_ newSerialNumbers: [String]) {
            guard serialNumbers != newSerialNumbers else {
                print("No changes to serial numbers; skipping update.")
                return
            }
            serialNumbers = newSerialNumbers
            print("Updated serial numbers: \(serialNumbers)")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black

            // Setup camera session and feedback views
            setupCaptureSession()
            setupFeedbackView()

            // Initialize Vision pipeline
            initializeVision()

            // Ensure feedback views are on top
            view.bringSubviewToFront(loadingLabel)
            view.bringSubviewToFront(activityIndicator)
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

        private func initializeVision() {
            print("Initializing Vision pipeline...")

            // Check if Vision is already ready
            if isVisionReady() {
                print("Vision is already ready.")
                self.hideFeedbackView()
                self.onVisionReady?(true)
                return
            }

            // Proceed to initialize Vision
            DispatchQueue.global(qos: .background).async {
                print("Vision not ready. Initializing pipeline...")

                // Simulate actual Vision initialization process (e.g., model loading)
                // Replace this block with the actual Vision initialization logic
                sleep(3) // Placeholder delay to simulate model loading

                DispatchQueue.main.async {
                    self.visionReady = true
                    print("Vision pipeline is fully initialized and ready!")
                    self.hideFeedbackView()
                    self.onVisionReady?(true) // Notify readiness if a callback is provided
                }
            }
        }

        private func setupFeedbackView() {
            guard !isFeedbackViewAdded else {
                print("Feedback view is already added, skipping setup.")
                return
            }
            isFeedbackViewAdded = true

            // Initialize feedback views
            loadingLabel = UILabel()
            loadingLabel.text = "Initializing Scanner..."
            loadingLabel.textColor = .white
            loadingLabel.textAlignment = .center
            loadingLabel.translatesAutoresizingMaskIntoConstraints = false

            activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.color = .white
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.startAnimating()

            // Add feedback views to the main view
            view.addSubview(loadingLabel)
            view.addSubview(activityIndicator)

            // Layout constraints for feedback views
            NSLayoutConstraint.activate([
                loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                loadingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicator.topAnchor.constraint(equalTo: loadingLabel.bottomAnchor, constant: 10)
            ])
        }

        private func hideFeedbackView() {
            DispatchQueue.main.async {
                print("Hiding feedback views.")
                self.loadingLabel.removeFromSuperview()
                self.activityIndicator.stopAnimating()
                self.activityIndicator.removeFromSuperview()
            }
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard visionReady else {
                // print("Vision not ready. Skipping frame.")
                return
            }

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

            let convertedBounds = previewLayer.layerRectConverted(fromMetadataOutputRect: bounds)

            DispatchQueue.main.async {
                self.highlightView.frame = convertedBounds
                self.view.bringSubviewToFront(self.highlightView)

                UIView.animate(withDuration: 0.2, animations: {
                    self.highlightView.alpha = 1
                }) { _ in
                    UIView.animate(withDuration: 0.2, animations: {
                        self.highlightView.alpha = 0
                    })
                }
            }
        }

        private func triggerHapticFeedback() {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            print("Haptics triggered.")
        }

        private func isVisionReady() -> Bool {
            print("Checking Vision readiness: \(visionReady ? "Ready" : "Not Ready")")
            return visionReady
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
