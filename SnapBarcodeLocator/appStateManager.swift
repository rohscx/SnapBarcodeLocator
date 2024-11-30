//
//  appStateManager.swift
//  barcodeScanner
//
//  Created by Fohristiwhirl on 11/28/24.
//

import Foundation
import AVFoundation
import SwiftUI

class AppStateManager: ObservableObject {
    @Published var cameraPermissionGranted: Bool = false
    @Published var serialNumbers: [String] = [] // Dynamic serial number list

    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
            case .authorized:
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = true
                }
                print("Camera Permission authorized")
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        self.cameraPermissionGranted = granted
                    }
                }
                print("Camera Permission notDetermined")
            case .denied, .restricted:
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = false
                }
                print("Camera Permission denied")
            @unknown default:
                DispatchQueue.main.async {
                    self.cameraPermissionGranted = false
                }
                print("Camera Permission unknown")
        }
    }
    func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            DispatchQueue.main.async {
                completion(true)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                completion(false)
            }
        @unknown default:
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }

}
