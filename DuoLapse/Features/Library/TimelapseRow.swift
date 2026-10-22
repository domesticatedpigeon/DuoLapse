import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct TimelapseRow: View {
    let recorder: TimelapseRecorder
    let store: SessionStore

    var body: some View {
        HStack(spacing: 12) {
            RecorderPreview(recorder: recorder, store: store)
                .frame(width: 64, height: 40)
                .clipShape(.rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(recorder.session.title)
                    .lineLimit(1)
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        [
            recorder.session.state.displayName,
            recorder.recordedDuration.compactRecordingTime,
            Int64(recorder.bytesOnDisk).formatted(.byteCount(style: .file)),
        ]
        .joined(separator: " · ")
    }
}
