//
//  PermissionDeniedView.swift
//  barcodeScanner
//
//  Created by Fohristiwhirl on 11/28/24.
//

import SwiftUI

struct PermissionDeniedView: View {
    var body: some View {
        VStack {
            Text("Camera Access Required")
                .font(.title)
                .padding()
            Text("Please enable camera access in your settings to use this app.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            Button(action: {
                openSettings()
            }) {
                Text("Open Settings")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    private func openSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
    }
}
