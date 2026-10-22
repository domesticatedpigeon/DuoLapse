public enum TimelapseState: String, Codable, Sendable, CaseIterable {
    case recording
    case paused
    case idlePaused
    case finished

    public var isCapturing: Bool {
        self == .recording
    }

    public var canResume: Bool {
        self == .paused || self == .idlePaused
    }
}
