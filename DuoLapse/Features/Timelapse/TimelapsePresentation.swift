import DuoLapseCore
import Foundation

extension TimelapseSession {
    var title: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
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

extension CaptureSource {
    var framesLabel: String {
        switch self {
        case .screen: "Screen frames"
        case .camera: "Camera frames"
        }
    }
}
