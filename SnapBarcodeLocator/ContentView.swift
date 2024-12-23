//
//  ContentView.swift
//  BarcodeScannerApp
//
//  Created by OpenAI Assistant on 11/29/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var inputText: String = "" // Input field text
    @State private var matchedCode: String?
    @State private var keyboardHeight: CGFloat = 0 // Track the keyboard height
    @FocusState private var isTextFieldFocused: Bool // Manage focus state for TextField
    @State private var isMenuOpen: Bool = false // Track menu visibility
    @Binding var serialNumbers: [String] // Pass as a binding
    @State private var scannedBarcodes: [String] = [] // Log of all scanned barcodes
    @State private var visionReady: Bool = false // Track Vision readiness

    var body: some View {
        NavigationView {
            VStack {
                // Barcode Scanner Section
                BarcodeScannerSection(
                    matchedCode: $matchedCode,
                    scannedBarcodes: $appStateManager.scannedBarcodes,
                    serialNumbers: $appStateManager.serialNumbers,
                    visionReady: $visionReady
                )

                Spacer()

                // Input Form Section
                InputFormSection(
                    inputText: $inputText,
                    serialNumbers: $appStateManager.serialNumbers,
                    isTextFieldFocused: $isTextFieldFocused,
                    keyboardHeight: $keyboardHeight
                )
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isMenuOpen.toggle()
                    }) {
                        Image(systemName: "line.horizontal.3") // Hamburger icon
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $isMenuOpen) {
                MenuView(serialNumbers: $appStateManager.serialNumbers, scannedBarcodes: $appStateManager.scannedBarcodes)
            }
            .background(Color.black.opacity(0.05)) // General background color
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            addKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
    }

    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardHeight = keyboardFrame.height
            }
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            self.keyboardHeight = 0
        }
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

struct BarcodeScannerSection: View {
    @Binding var matchedCode: String?
    @Binding var scannedBarcodes: [String]
    @Binding var serialNumbers: [String]
    @Binding var visionReady: Bool
    @State private var isTorchOn: Bool = false // Track flashlight

    var body: some View {
        VStack {
            ZStack {
                BarcodeScannerView(
                    serialNumbers: $serialNumbers,
                    onScanned: { scannedValue in
                        // Add all scanned barcodes to the list
                        if !scannedBarcodes.contains(scannedValue) {
                            scannedBarcodes.append(scannedValue)
                            print("Scanned barcode added: \(scannedValue)")
                        } else {
                            print("Duplicate barcode ignored: \(scannedValue)")
                        }

                        // Check if the scanned barcode matches a serial number
                        if serialNumbers.contains(scannedValue) {
                            matchedCode = scannedValue
                            print("Matched serial number: \(scannedValue)")
                        } else {
                            print("Scanned value: \(scannedValue) did not match any serial numbers.")
                        }
                    },
                    onVisionReady: { isReady in
                        print("Vision readiness updated: \(isReady)")
                        self.visionReady = isReady
                    }
                )
                .frame(height: UIScreen.main.bounds.height * 0.5)
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
                .padding()

                // Flashlight Toggle Button in the Top-Right Corner
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            toggleTorch()
                        }) {
                            Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                                .shadow(radius: 10)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }

            // Display matched code or prompt
            if let code = matchedCode {
                Text("\(code)")
                    .font(.title)
                    // .padding()
                    .foregroundColor(.green)
            } else {
                Text("Scan a barcode to match!")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }

    private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("Torch is not available on this device.")
            return
        }

        do {
            try device.lockForConfiguration()
            device.torchMode = isTorchOn ? .off : .on
            isTorchOn.toggle()
            device.unlockForConfiguration()
        } catch {
            print("Error toggling the torch: \(error.localizedDescription)")
        }
    }
}


struct InputFormSection: View {
    @Binding var inputText: String
    @Binding var serialNumbers: [String]
    @FocusState.Binding var isTextFieldFocused: Bool
    @Binding var keyboardHeight: CGFloat

    var body: some View {
        VStack(spacing: 16) {
            // TextField with interactive placeholder
            ZStack(alignment: .leading) {
                if inputText.isEmpty {
                    Text("Enter serial number(s)")
                        .foregroundColor(.gray)
                        .padding(.leading, 15)
                }
                TextField("", text: $inputText)
                    .foregroundColor(.black) // Text color
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .focused($isTextFieldFocused)
            }

            // Submit Button
            Button(action: {
                handleTextSubmission()
            }) {
                Text("Submit Serial Number(s)")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding([.leading, .trailing], 20)
        .padding(.bottom, keyboardHeight)
        .animation(.easeOut, value: keyboardHeight)
    }

    private func handleTextSubmission() {
        let newSerials = inputText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if !newSerials.isEmpty {
            serialNumbers.append(contentsOf: newSerials)
            print("New serials added: \(newSerials)")
        }
        inputText = "" // Clear the input field
        isTextFieldFocused = false // Dismiss the keyboard
    }
}
