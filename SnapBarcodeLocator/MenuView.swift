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
                // Section for serial numbers
                Section(header: Text("Entered Serial Numbers")) {
                    if serialNumbers.isEmpty {
                        Text("No serial numbers entered yet")
                            .foregroundColor(.gray)
                            .textSelection(.disabled) // Prevent selection for placeholder text
                    } else {
                        ForEach(serialNumbers, id: \.self) { serial in
                            HStack {
                                Text(serial)
                                    .textSelection(.enabled) // Make text selectable
                                    .padding(.trailing, 8)
                                Spacer()
                                Image(systemName: "trash") // Trash icon for removal
                                    .foregroundColor(.red)
                                    .onTapGesture {
                                        removeFromSerialNumbers(serial)
                                    }
                            }
                        }
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
                                    .padding(.trailing, 8) // Add some spacing
                                Image(systemName: "plus.circle") // Add icon
                                    .foregroundColor(.green)
                                    .onTapGesture {
                                        addToSerialNumbers(barcode)
                                    }
                                    .padding(.trailing, 8) // Add some spacing
                                Image(systemName: "trash") // Trash icon for removal
                                    .foregroundColor(.red)
                                    .onTapGesture {
                                        removeScannedBarcode(barcode)
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

                // Export Barcodes
                Section {
                    Button("Export Scanned Barcodes") {
                        exportCSV(scannedBarcodes: scannedBarcodes)
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

    // MARK: - Helper Functions

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

    // Function to add barcode to serial numbers
    private func addToSerialNumbers(_ barcode: String) {
        if !serialNumbers.contains(barcode) {
            serialNumbers.append(barcode)
            print("Added \(barcode) to serial numbers")
        } else {
            print("\(barcode) already exists in serial numbers")
        }
    }

    // Function to remove a serial number
    private func removeFromSerialNumbers(_ serial: String) {
        if let index = serialNumbers.firstIndex(of: serial) {
            serialNumbers.remove(at: index)
            print("Removed \(serial) from serial numbers")
        } else {
            print("\(serial) not found in serial numbers")
        }
    }

    // Function to remove a serial number
    private func removeScannedBarcode(_ barcode: String) {
        if let index = scannedBarcodes.firstIndex(of: barcode) {
            scannedBarcodes.remove(at: index)
            print("Removed scanned barcode: \(barcode)")
        } else {
            print("\(barcode) not found in scanned barcodes")
        }
    }
}
