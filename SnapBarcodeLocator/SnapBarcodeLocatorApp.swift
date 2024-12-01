//
//  barcodeScannerApp.swift
//  barcodeScanner
//
//  Created by Fohristiwhirl on 11/28/24.
//

import SwiftUI

@main
struct barcodeScannerApp: App {
    @StateObject private var appStateManager = AppStateManager() // Manage app state

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appStateManager) // Pass the object globally
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appStateManager: AppStateManager

    var body: some View {
        Group {
            if appStateManager.cameraPermissionGranted {
                // Pass serialNumbers as a binding
                ContentView(serialNumbers: $appStateManager.serialNumbers)
            } else {
                PermissionDeniedView()
            }
        }
        .onAppear {
            appStateManager.checkCameraPermission() // Check permission here
        }
    }
}
