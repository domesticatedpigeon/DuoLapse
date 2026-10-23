public struct PixelSize: Hashable, Codable, Sendable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public var longEdge: Int {
        max(width, height)
    }

    public func fitting(longEdge maximumLongEdge: Int) -> PixelSize {
        let scale = min(1, Double(maximumLongEdge) / Double(max(longEdge, 1)))
        return PixelSize(
            width: Self.evenDimension(Double(width) * scale),
            height: Self.evenDimension(Double(height) * scale)
        )
    }

    private static func evenDimension(_ value: Double) -> Int {
        max(2, Int((value / 2).rounded(.down)) * 2)
    }
}
