import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct TimelapseRow: View {
    let recorder: TimelapseRecorder
    let store: SessionStore
    let isRenaming: Bool
    let onRename: (String) -> Void
    let onCancelRename: () -> Void
    @State private var draftName = ""
    @FocusState private var isNameFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    var body: some View {
        HStack(spacing: 12) {
            RecorderSourcesPreview(recorder: recorder, store: store, style: .compact, thumbnailSide: 192)
                .frame(width: 96)

            VStack(alignment: .leading, spacing: 2) {
                if isRenaming {
                    TextField("Name", text: $draftName, prompt: Text(recorder.session.title))
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                        .focused($isNameFieldFocused)
                        .onSubmit { onRename(draftName) }
                        .onExitCommand(perform: onCancelRename)
                        .onChange(of: isNameFieldFocused) { _, isFocused in
                            if !isFocused { onRename(draftName) }
                        }
                        .onAppear {
                            draftName = recorder.session.title
                            isNameFieldFocused = true
                        }
                } else {
                    Text(recorder.session.title)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    Image(systemName: recorder.session.state.symbolName)
                        .foregroundStyle(recorder.session.state.symbolColor)
                        .symbolEffect(
                            .pulse.wholeSymbol, options: .repeat(.continuous),
                            isActive: recorder.isCapturing && !reducesMotion
                        )
                        .accessibilityHidden(true)
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(summary)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: isRenaming ? .contain : .combine)
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
