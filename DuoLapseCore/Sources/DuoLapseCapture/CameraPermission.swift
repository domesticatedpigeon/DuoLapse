import AVFoundation
import AppKit

public enum CameraPermission {
    nonisolated public enum Status: Sendable {
        case notDetermined
        case granted
        case denied
    }

    public static var status: Status {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: .granted
        case .notDetermined: .notDetermined
        default: .denied
        }
    }

    public static func request() async -> Status {
        await AVCaptureDevice.requestAccess(for: .video) ? .granted : .denied
    }

    public static func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
