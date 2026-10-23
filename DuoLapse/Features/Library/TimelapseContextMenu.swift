import DuoLapseCapture
import SwiftUI

struct TimelapseContextMenu: View {
    let library: TimelapseLibrary
    let recorder: TimelapseRecorder
    let perform: (@escaping @MainActor () async throws -> Void) -> Void
    let onExport: () -> Void
    let onRename: () -> Void
    let onShowInFinder: () -> Void
    let onMoveToTrash: () -> Void

    var body: some View {
        switch recorder.session.state {
        case .recording:
            Button("Pause", systemImage: "pause.fill") { perform { try await library.pause(recorder) } }
            Button("Close", systemImage: "stop.fill") { perform { try await library.stop(recorder) } }
        case .paused, .idlePaused:
            Button("Resume", systemImage: "record.circle") { perform { try await library.record(recorder) } }
            Button("Close", systemImage: "stop.fill") { perform { try await library.stop(recorder) } }
        case .finished:
            Button("Reopen", systemImage: "arrow.uturn.backward.circle") { perform { try library.reopen(recorder) } }
        }
        Divider()
        Button("Export…", systemImage: "square.and.arrow.up", action: onExport)
            .disabled(recorder.session.capturedFrameCount == 0)
        Button("Rename…", systemImage: "pencil", action: onRename)
        Button("Show in Finder", systemImage: "folder", action: onShowInFinder)
        Divider()
        Button("Move to Trash…", systemImage: "trash", role: .destructive, action: onMoveToTrash)
    }
}
