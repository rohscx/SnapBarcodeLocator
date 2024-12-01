import Foundation
import AVFoundation
import SwiftUI

class AppStateManager: ObservableObject {
    @Published var cameraPermissionGranted: Bool = false
    @Published var serialNumbers: [String] = [] // Dynamic serial number list
    @Published var scannedBarcodes: [String] = [] {
        didSet {
            guard oldValue != scannedBarcodes else {
                print("No changes in scanned barcodes; skipping update.")
                return
            }
            print("Scanned barcodes updated: \(scannedBarcodes)")
        }
    }

    /// Checks and updates the camera permission status
    func checkCameraPermission(completion: ((Bool) -> Void)? = nil) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            updatePermissionStatus(granted: true, completion: completion)
            print("Camera Permission authorized")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                self.updatePermissionStatus(granted: granted, completion: completion)
            }
            print("Camera Permission notDetermined, requesting access")
        case .denied, .restricted:
            updatePermissionStatus(granted: false, completion: completion)
            print("Camera Permission denied or restricted")
        @unknown default:
            updatePermissionStatus(granted: false, completion: completion)
            print("Camera Permission unknown")
        }
    }

    /// Helper to update the cameraPermissionGranted and execute a completion
    private func updatePermissionStatus(granted: Bool, completion: ((Bool) -> Void)?) {
        DispatchQueue.main.async {
            self.cameraPermissionGranted = granted
            completion?(granted)
        }
    }
}
