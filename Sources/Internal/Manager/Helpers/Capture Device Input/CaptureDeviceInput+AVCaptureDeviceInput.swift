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

extension AVCaptureDeviceInput: CaptureDeviceInput {
    static func get(mediaType: AVMediaType, position: AVCaptureDevice.Position?) -> Self? {
        let device = { switch mediaType {
            case .audio: AVCaptureDevice.default(for: .audio)
            case .video where position == .front: AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            case .video where position == .back: getBestAvailableBackCamera()
            default: fatalError()
        }}()

        guard let device, let deviceInput = try? Self(device: device) else { return nil }
        return deviceInput
    }
    
    private static func getBestAvailableBackCamera() -> AVCaptureDevice? {
        // Try virtual devices in priority order for enhanced zoom capabilities
        // 1. builtInTripleCamera: ultra-wide, wide, and telephoto (iPhone 11 Pro and later)
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            return device
        }
        // 2. builtInDualWideCamera: ultra-wide and wide (iPhone 11 and later)
        if let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
            return device
        }
        // 3. builtInDualCamera: wide and telephoto (iPhone 7 Plus and later)
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return device
        }
        // 4. Fallback to builtInWideAngleCamera
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }
}
