public struct CaptureSettings: Hashable, Codable, Sendable {
    public var captureIntervalSeconds: Int
    public var storageResolution: StorageResolution
    public var displayUUID: String?
    public var cameraID: String?

    public init(
        captureIntervalSeconds: Int,
        storageResolution: StorageResolution,
        displayUUID: String?,
        cameraID: String?
    ) {
        self.captureIntervalSeconds = max(1, captureIntervalSeconds)
        self.storageResolution = storageResolution
        self.displayUUID = displayUUID
        self.cameraID = cameraID
    }

    public var captureInterval: Duration {
        .seconds(captureIntervalSeconds)
    }

    public var sources: [CaptureSource] {
        [displayUUID.map { _ in .screen }, cameraID.map { _ in .camera }].compactMap(\.self)
    }
}
