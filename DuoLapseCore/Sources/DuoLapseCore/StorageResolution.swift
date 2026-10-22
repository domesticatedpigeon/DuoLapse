public enum StorageResolution: String, Codable, Sendable, CaseIterable {
    case standard
    case high

    public var maximumLongEdge: Int {
        switch self {
        case .standard: 1920
        case .high: 2560
        }
    }

    public func storageSize(for sourceSize: PixelSize) -> PixelSize {
        let scale = min(1, Double(maximumLongEdge) / Double(max(sourceSize.longEdge, 1)))
        return PixelSize(
            width: Self.evenDimension(Double(sourceSize.width) * scale),
            height: Self.evenDimension(Double(sourceSize.height) * scale)
        )
    }

    private static func evenDimension(_ value: Double) -> Int {
        max(2, Int((value / 2).rounded(.down)) * 2)
    }
}
