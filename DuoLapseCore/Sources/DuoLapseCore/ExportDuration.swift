public enum ExportDuration: Hashable, Codable, Sendable {
    case seconds(Int)
    case fullLength

    public static let framesPerSecond = 30
    public static let presets: [ExportDuration] = [.seconds(30), .seconds(60), .seconds(180), .fullLength]

    public var isPreset: Bool {
        Self.presets.contains(self)
    }

    public func frameCount(availableFrames: Int) -> Int {
        switch self {
        case .seconds(let seconds): min(availableFrames, max(1, seconds) * Self.framesPerSecond)
        case .fullLength: availableFrames
        }
    }

    public func fits(availableFrames: Int) -> Bool {
        switch self {
        case .seconds(let seconds): seconds * Self.framesPerSecond <= availableFrames
        case .fullLength: availableFrames > 0
        }
    }

    public static func fullLengthSeconds(availableFrames: Int) -> Double {
        Double(availableFrames) / Double(framesPerSecond)
    }
}
