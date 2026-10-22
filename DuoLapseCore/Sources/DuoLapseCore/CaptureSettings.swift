public struct CaptureSettings: Hashable, Codable, Sendable {
    public var captureIntervalSeconds: Int
    public var displayUUID: String
    public var storageResolution: StorageResolution

    public init(captureIntervalSeconds: Int, displayUUID: String, storageResolution: StorageResolution) {
        self.captureIntervalSeconds = max(1, captureIntervalSeconds)
        self.displayUUID = displayUUID
        self.storageResolution = storageResolution
    }

    public var captureInterval: Duration {
        .seconds(captureIntervalSeconds)
    }
}
