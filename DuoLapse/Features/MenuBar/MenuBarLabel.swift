import DuoLapseCapture
import SwiftUI

struct MenuBarLabel: View {
    let library: TimelapseLibrary

    var body: some View {
        if let active = library.activeRecorder {
            let _ = library.heartbeat
            Label {
                Text(active.recordedDuration.compactRecordingTime)
                    .monospacedDigit()
            } icon: {
                Image(systemName: "timer")
            }
            .labelStyle(.titleAndIcon)
            .accessibilityLabel("DuoLapse recording, \(active.recordedDuration.compactRecordingTime)")
        } else {
            Image(systemName: library.hasRecordingInProgress ? "pause.circle" : "timer")
                .accessibilityLabel("DuoLapse")
        }
    }
}
