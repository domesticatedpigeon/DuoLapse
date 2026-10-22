import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct TimelapseRow: View {
    let recorder: TimelapseRecorder
    let store: SessionStore

    var body: some View {
        HStack(spacing: 12) {
            TimelapseThumbnail(session: recorder.session, store: store, maximumSide: 120)
                .frame(width: 64, height: 40)
                .clipShape(.rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(recorder.session.title)
                    .lineLimit(1)
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        [
            recorder.session.state.displayName,
            recorder.session.recordedSeconds.formattedRecordingTime,
            Int64(recorder.bytesOnDisk).formatted(.byteCount(style: .file)),
        ]
        .joined(separator: " · ")
    }
}
