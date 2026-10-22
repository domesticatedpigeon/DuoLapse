import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct RecordingStatusSection: View {
    let recorder: TimelapseRecorder

    var body: some View {
        Section("Timelapse") {
            LabeledContent("Status", value: recorder.session.state.displayName)
            ForEach(recorder.session.settings.sources, id: \.self) { source in
                LabeledContent(source.framesLabel, value: recorder.capturedFrameCounts[source, default: 0].formatted())
            }
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

extension CaptureSource {
    fileprivate var framesLabel: String {
        switch self {
        case .screen: "Screen frames"
        case .camera: "Camera frames"
        }
    }
}
