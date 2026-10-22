import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct RecordingStatusSection: View {
    let recorder: TimelapseRecorder

    var body: some View {
        Section("Timelapse") {
            LabeledContent("Status", value: recorder.session.state.displayName)
            LabeledContent("Frames captured", value: recorder.capturedFrameCount.formatted())
            LabeledContent("Size on disk", value: Int64(recorder.bytesOnDisk).formatted(.byteCount(style: .file)))
            if let lastCaptureError = recorder.lastCaptureError {
                Label(lastCaptureError, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension TimelapseState {
    fileprivate var displayName: String {
        switch self {
        case .recording: "Recording"
        case .paused: "Paused"
        case .idlePaused: "Paused while idle"
        case .finished: "Finished"
        }
    }
}
