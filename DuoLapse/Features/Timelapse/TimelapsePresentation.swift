import DuoLapseCore
import Foundation

extension TimelapseSession {
    var title: String {
        name ?? createdAt.formatted(date: .abbreviated, time: .shortened)
    }
}

extension TimelapseState {
    var displayName: String {
        switch self {
        case .recording: "Recording"
        case .paused: "Paused"
        case .idlePaused: "Paused while you’re away"
        case .finished: "Closed"
        }
    }
}

extension Duration {
    var compactRecordingTime: String {
        RecordingTimeFormat.compact(seconds: Double(components.seconds))
    }
}
