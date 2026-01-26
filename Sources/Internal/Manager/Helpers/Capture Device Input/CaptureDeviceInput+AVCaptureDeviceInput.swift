//
//  CaptureDeviceInput+AVCaptureDeviceInput.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import AVKit
import AVFoundation

extension AVCaptureDeviceInput: CaptureDeviceInput {
    static func get(mediaType: AVMediaType, position: AVCaptureDevice.Position?) -> Self? {
        let device = { switch mediaType {
            case .audio: AVCaptureDevice.default(for: .audio)
            case .video where position == .front: AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            case .video where position == .back: getBestAvailableBackCamera()
            default: fatalError()
        }}()

        guard let device else { return nil }
        
        // For virtual camera devices, log switch-over factors for debugging
        if mediaType == .video && position == .back {
            let deviceType = device.deviceType
            if deviceType == .builtInTripleCamera || deviceType == .builtInDualWideCamera {
                do {
                    try device.lockForConfiguration()
                    let switchOvers = device.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat(truncating: $0) }
                    let minZoom = device.minAvailableVideoZoomFactor
                    let maxZoom = device.maxAvailableVideoZoomFactor
                    device.unlockForConfiguration()
                    print("📷 Virtual camera: minZoom=\(minZoom), maxZoom=\(maxZoom), switchOvers=\(switchOvers)")
                } catch {
                    print("⚠️ Could not query virtual camera properties: \(error)")
                }
            }
        }
        
        guard let deviceInput = try? Self(device: device) else { return nil }
        return deviceInput
    }
    
    private static func getBestAvailableBackCamera() -> AVCaptureDevice? {
        // Use discovery session to find available devices
        // This works even when devices might be in use
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTripleCamera,
                .builtInDualWideCamera,
                .builtInDualCamera,
                .builtInWideAngleCamera
            ],
            mediaType: .video,
            position: .back
        )
        
        let availableDevices = discoverySession.devices
        print("📷 Library: Available back camera devices: \(availableDevices.map { $0.deviceType.rawValue })")
        
        // Try virtual devices in priority order for enhanced zoom capabilities
        // 1. builtInTripleCamera: ultra-wide, wide, and telephoto (iPhone 11 Pro and later)
        if let device = availableDevices.first(where: { $0.deviceType == .builtInTripleCamera }) {
            print("📷 Library: Selected builtInTripleCamera")
            return device
        }
        // 2. builtInDualWideCamera: ultra-wide and wide (iPhone 11 and later)
        if let device = availableDevices.first(where: { $0.deviceType == .builtInDualWideCamera }) {
            print("📷 Library: Selected builtInDualWideCamera")
            return device
        }
        // 3. builtInDualCamera: wide and telephoto (iPhone 7 Plus and later)
        if let device = availableDevices.first(where: { $0.deviceType == .builtInDualCamera }) {
            print("📷 Library: Selected builtInDualCamera")
            return device
        }
        // 4. Fallback to builtInWideAngleCamera
        if let device = availableDevices.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
            print("📷 Library: Selected builtInWideAngleCamera (fallback)")
            return device
        }
        
        // Ultimate fallback: try direct query (may return nil if device in use)
        print("⚠️ Library: No devices in discovery session, trying direct query")
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return device
        }
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }
}
