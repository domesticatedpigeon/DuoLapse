public enum StorageResolution: String, Codable, Sendable, CaseIterable {
    case standard
    case high

    public static let cameraLongEdge = 1280

    public var screenLongEdge: Int {
        switch self {
        case .standard: 1920
        case .high: 2560
        }
    }

    public func screenStorageSize(for sourceSize: PixelSize) -> PixelSize {
        sourceSize.fitting(longEdge: screenLongEdge)
    }

    public static func cameraStorageSize(for sourceSize: PixelSize) -> PixelSize {
        sourceSize.fitting(longEdge: cameraLongEdge)
    }
}
