//
//  CameraView+Bridge.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI

struct CameraBridgeView: UIViewRepresentable {
    let cameraManager: CameraManager
    let inputView: UIView = .init()
}
extension CameraBridgeView {
    func makeUIView(context: Context) -> some UIView {
        cameraManager.initialize(in: inputView)
        setupTapGesture(context)
        setupPinchGesture(context)
        return inputView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    func makeCoordinator() -> Coordinator { .init(self) }
}
private extension CameraBridgeView {
    func setupTapGesture(_ context: Context) {
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.onTapGesture))
        inputView.addGestureRecognizer(tapRecognizer)
    }
    func setupPinchGesture(_ context: Context) {
        let pinchRecognizer = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.onPinchGesture))
        inputView.addGestureRecognizer(pinchRecognizer)
    }
}

// MARK: Equatable
extension CameraBridgeView: Equatable {
    nonisolated static func ==(lhs: Self, rhs: Self) -> Bool { true }
}


// MARK: - GESTURES
extension CameraBridgeView {
    class Coordinator: NSObject {
        let parent: CameraBridgeView
        var lastPinchZoom: CGFloat = 1.0  // Track zoom level when pinch gesture started
        
        init(_ parent: CameraBridgeView) {
            self.parent = parent
        }
    }
}

// MARK: On Tap
extension CameraBridgeView.Coordinator {
    @MainActor @objc func onTapGesture(_ tap: UITapGestureRecognizer) {
        do {
            let touchPoint = tap.location(in: parent.inputView)
            try parent.cameraManager.setCameraFocus(at: touchPoint)
        } catch {
            print("⚠️ Failed to set camera focus: \(error.localizedDescription)")
        }
    }
}

// MARK: On Pinch
extension CameraBridgeView.Coordinator {
    @MainActor @objc func onPinchGesture(_ pinch: UIPinchGestureRecognizer) {
        do {
            if pinch.state == .began {
                // Store the zoom level at gesture start
                lastPinchZoom = parent.cameraManager.attributes.zoomFactor
            }
            
            if pinch.state == .changed {
                // Use scale multiplicatively - this is naturally symmetric
                // scale = 2.0 means 2x zoom in, scale = 0.5 means 2x zoom out
                let desiredZoomFactor = lastPinchZoom * pinch.scale
                
                // Cap zoom at practical max (10x display)
                // Back camera (virtual device): 10x display = 20x internal
                // Front camera (single wide-angle): 10x display = 10x internal
                let isBackCamera = parent.cameraManager.attributes.cameraPosition == .back
                let practicalMaxZoom: CGFloat = isBackCamera ? 20.0 : 10.0
                let minZoom: CGFloat = 1.0
                let clampedZoomFactor = min(max(desiredZoomFactor, minZoom), practicalMaxZoom)
                
                try parent.cameraManager.setCameraZoomFactor(clampedZoomFactor)
            }
        } catch {
            print("⚠️ Failed to set camera zoom: \(error.localizedDescription)")
        }
    }
}
