import DuoLapseCapture
import SwiftUI

struct MenuBarLabel: View {
    let library: TimelapseLibrary

    var body: some View {
        if let active = library.activeRecorder {
            let _ = library.heartbeat
            Label {
                Text(active.recordedDuration.formatted(.time(pattern: .hourMinuteSecond)))
                    .monospacedDigit()
            } icon: {
                Image(systemName: "record.circle.fill")
            }
            .labelStyle(.titleAndIcon)
            .accessibilityLabel("DuoLapse, recording")
        } else {
            Image(systemName: library.hasRecordingInProgress ? "pause.circle" : "camera.aperture")
                .accessibilityLabel("DuoLapse")
        }
    }
}
