import DuoLapseCore
import Foundation
import SwiftUI

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

    var symbolName: String {
        switch self {
        case .recording: "record.circle.fill"
        case .paused: "pause.circle.fill"
        case .idlePaused: "moon.zzz.fill"
        case .finished: "checkmark.circle.fill"
        }
    }

    var symbolColor: Color {
        switch self {
        case .recording: .red
        case .paused, .idlePaused: .orange
        case .finished: .secondary
        }
    }
}

extension Duration {
    var compactRecordingTime: String {
        RecordingTimeFormat.compact(seconds: Double(components.seconds))
    }
}
