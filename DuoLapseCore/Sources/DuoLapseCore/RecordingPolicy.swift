public enum IdleAction: Equatable, Sendable {
    case none
    case pauseForIdle
    case resumeFromIdle
}

public enum RecordingPolicy {
    public static let idleSecondsBeforePause: Double = 60
    public static let idleSecondsCountedAsActive: Double = 2
    public static let minimumFreeBytes: Int64 = 2_000_000_000
    public static let screenFailureSecondsBeforePause: Double = 30

    public static func idleAction(
        for state: TimelapseState,
        idleSeconds: Double,
        isSmartPauseEnabled: Bool
    ) -> IdleAction {
        switch state {
        case .recording where isSmartPauseEnabled && idleSeconds >= idleSecondsBeforePause:
            .pauseForIdle
        case .idlePaused where idleSeconds < idleSecondsCountedAsActive:
            .resumeFromIdle
        default:
            .none
        }
    }

    public static func shouldPreventSleep(states: [TimelapseState], isKeepAwakeEnabled: Bool) -> Bool {
        isKeepAwakeEnabled && states.contains { $0 == .recording || $0 == .idlePaused }
    }

    public static func hasEnoughFreeSpace(availableBytes: Int64) -> Bool {
        availableBytes >= minimumFreeBytes
    }

    public static func shouldPauseForScreenFailures(failingForSeconds: Double) -> Bool {
        failingForSeconds >= screenFailureSecondsBeforePause
    }
}
