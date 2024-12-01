---

# SnapBarcodeLocator

SnapBarcodeLocator is a Swift-based iOS application designed to scan and track barcodes in real-time. The app integrates high-resolution video streaming using AVFoundation, enabling robust barcode detection, matching, and data management. Whether you're working with EAN, QR, Code128, or other barcode formats, SnapBarcodeLocator simplifies the process of identifying and organizing barcodes efficiently.

---

## Features

- **Barcode Scanning:** Supports multiple barcode formats, including EAN8, EAN13, Code128, QR, PDF417, Code39, and more.
- **Real-Time Detection:** Leverages AVFoundation for high-performance scanning in real-time.
- **Serial Number Matching:** Compares scanned barcodes against a user-provided list of serial numbers to detect matches.
- **Barcode Highlighting:** Visual bounding boxes highlight scanned barcodes for better user feedback.
- **Clipboard Integration:** Easily copy scanned barcodes or add/remove serial numbers via a seamless interface.
- **Haptic Feedback:** Triggered upon successfully matching a barcode with serial numbers.
- **Error Handling:** Graceful handling of camera permissions and device compatibility issues.

---

## Requirements

- **iOS Version:** iOS 14.0 or later
- **Xcode:** Version 14 or later
- **Language:** Swift
- **Frameworks Used:** AVFoundation, SwiftUI

---

## Installation

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/your-username/SnapBarcodeLocator.git
   cd SnapBarcodeLocator
   ```

2. **Open in Xcode:**
   Open the `SnapBarcodeLocator.xcodeproj` file in Xcode.

3. **Build and Run:**
   Select a device or simulator and click the "Run" button in Xcode.

4. **Permissions:**
   Ensure camera permissions are enabled in your app settings.

---

## Usage

1. **Scanning Barcodes:**
   - The app automatically scans barcodes in the camera's field of view.
   - Scanned barcodes are highlighted and displayed in the list.

2. **Matching Serial Numbers:**
   - Add serial numbers to the match list using the "Add Serial Number" field.
   - Matching barcodes are highlighted, and haptic feedback is triggered.

3. **Clipboard Integration:**
   - Copy individual scanned barcodes to the clipboard using the "Copy" button.
   - Add or remove serial numbers with ease.

4. **Managing Data:**
   - Reset the scanned barcode list or the serial numbers list via the menu options.

---

## File Structure

- `BarcodeScannerView.swift`: Core implementation of the barcode scanner using AVFoundation.
- `ContentView.swift`: Main interface for barcode scanning and serial number matching.
- `appStateManager.swift`: State management for the app.
- `MenuView.swift`: Menu for managing scanned barcodes and serial numbers.
- `SnapBarcodeLocatorApp.swift`: App lifecycle and configuration.
- `PermissionDeniedView.swift`: View displayed when camera permissions are not granted.

---

## Customization

- **Barcode Formats:** Modify supported barcode types in `metadataOutput.metadataObjectTypes` within `BarcodeScannerView.swift`.
- **UI Enhancements:** Update SwiftUI views in `ContentView.swift` and `MenuView.swift` for a customized interface.
- **Camera Settings:** Adjust camera resolution and focus behavior in `BarcodeScannerView.swift`.

---

## Contributions

Contributions, issues, and feature requests are welcome. Feel free to fork the repository and submit pull requests.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---
