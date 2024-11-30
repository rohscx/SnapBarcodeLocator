//
//  MenuView.swift
//  barcodeScanner
//
//  Created by OpenAI Assistant on 11/29/24.
//

import SwiftUI

struct MenuView: View {
    @Binding var serialNumbers: [String] // Bind to the list of entered serial numbers
    @Binding var scannedBarcodes: [String] // Bind to the list of scanned barcodes
    @Environment(\.dismiss) var dismiss // Dismiss the menu

    var body: some View {
        NavigationView {
            List {
                // Section for entered serial numbers
                Section(header: Text("Entered Serial Numbers")) {
                    ForEach(serialNumbers, id: \.self) { serial in
                        Text(serial)
                            .textSelection(.enabled) // Ensure serial numbers are selectable
                    }
                }

                // Section for scanned barcodes
                Section(header: Text("Scanned Barcodes")) {
                    if scannedBarcodes.isEmpty {
                        Text("No barcodes scanned yet")
                            .foregroundColor(.gray)
                            .textSelection(.disabled) // Prevent selection for placeholder text
                    } else {
                        ForEach(scannedBarcodes, id: \.self) { barcode in
                            HStack {
                                Text(barcode)
                                    .textSelection(.enabled) // Ensure barcodes are selectable
                                    .padding(.trailing, 8)
                                Spacer()
                                Image(systemName: "doc.on.clipboard") // Clipboard icon
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                        copyToClipboard(barcode)
                                    }
                            }
                        }
                    }
                }

                // Reset buttons
                Section {
                    Button(role: .destructive, action: {
                        resetSerialNumbers()
                    }) {
                        Text("Reset Serial Numbers")
                    }

                    Button(role: .destructive, action: {
                        resetScannedBarcodes()
                    }) {
                        Text("Reset Scanned Barcodes")
                    }
                }
            }
            .navigationTitle("Menu")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss() // Close the menu
                    }
                }
            }
        }
    }

    // Copy the barcode to the clipboard
    private func copyToClipboard(_ barcode: String) {
        UIPasteboard.general.string = barcode
        print("Copied to clipboard: \(barcode)")
    }

    private func resetSerialNumbers() {
        serialNumbers.removeAll() // Clear the serial numbers
    }

    private func resetScannedBarcodes() {
        scannedBarcodes.removeAll() // Clear the scanned barcodes
    }
}
