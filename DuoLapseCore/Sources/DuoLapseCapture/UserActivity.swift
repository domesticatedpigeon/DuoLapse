import CoreGraphics

enum UserActivity {
    static var secondsSinceLastInput: Double {
        guard let anyInputEvent = CGEventType(rawValue: ~0) else { return 0 }
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInputEvent)
    }
}
