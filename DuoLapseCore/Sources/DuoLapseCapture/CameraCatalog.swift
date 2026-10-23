import AVFoundation

nonisolated public struct CapturableCamera: Identifiable, Hashable, Sendable {
    public let uniqueID: String
    public let name: String

    public var id: String {
        uniqueID
    }
}

public enum CameraCatalog {
    public static func availableCameras() -> [CapturableCamera] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external, .continuityCamera],
            mediaType: .video,
            position: .unspecified
        )
        .devices
        .map { CapturableCamera(uniqueID: $0.uniqueID, name: $0.localizedName) }
    }
}
