//
//  FileExports.swift
//  barcodeScanner
//
//  Created by OpenAI Assistant on 12/06/24.
//

import Foundation
import SwiftUI

func exportCSV(scannedBarcodes: [String]) {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentsDirectory.appendingPathComponent("ScannedBarcodes.csv")

    do {
        // Prepare CSV header and rows
        var csvContent = "Barcode\n" // Header
        csvContent += scannedBarcodes.map { "\"\($0)\"" }.joined(separator: "\n") // Add each barcode in a new row, with values wrapped in quotes for safety.

        // Write the content to the file
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        print("CSV exported to: \(fileURL)")

        // Verify file existence
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("File does not exist at \(fileURL)")
            return
        }

        // Present UIActivityViewController
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            activityVC.excludedActivityTypes = [.assignToContact, .addToReadingList] // Optional exclusions

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                if rootViewController.presentedViewController == nil {
                    rootViewController.present(activityVC, animated: true, completion: nil)
                } else {
                    print("Another view is already presented. Dismissing it.")
                    rootViewController.dismiss(animated: true) {
                        rootViewController.present(activityVC, animated: true, completion: nil)
                    }
                }
            } else {
                print("Failed to get the root view controller.")
            }
        }
    } catch {
        print("Error exporting CSV: \(error.localizedDescription)")
    }
}
