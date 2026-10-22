import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct TimelapseDetailView: View {
    let library: TimelapseLibrary
    let navigation: AppNavigation
    let recorder: TimelapseRecorder
    @State private var isChangingState = false
    @State private var isExporting = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                RecorderSourcesPreview(recorder: recorder, store: library.store)
            }

            Section("Status") {
                LabeledContent("State", value: recorder.session.state.displayName)
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    LabeledContent(
                        "Recorded time",
                        value: recorder.recordedDuration.compactRecordingTime
                    )
                }
                LabeledContent("Size on disk", value: Int64(recorder.bytesOnDisk).formatted(.byteCount(style: .file)))
                if let lastCaptureError = recorder.lastCaptureError {
                    Label(lastCaptureError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
            }

            SourceSwitcherSection(library: library, recorder: recorder) { message in
                errorMessage = message
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Library")
        .navigationSubtitle(recorder.session.title)
        .toolbar {
            toolbarContent
        }
        .onChange(of: navigation.exportRequestID, initial: true) { _, requestedID in
            guard requestedID == recorder.session.id else { return }
            navigation.exportRequestID = nil
            isExporting = true
        }
        .sheet(isPresented: $isExporting) {
            ExportSheet(session: recorder.session, store: library.store)
        }
        .alert("Something Went Wrong", isPresented: isShowingError, presenting: errorMessage) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Button("Export…", systemImage: "square.and.arrow.up") {
                isExporting = true
            }
            .help("Export")
            .disabled(recorder.isCapturing || recorder.session.capturedFrameCount == 0)
        }

        ToolbarSpacer(.fixed)

        ToolbarItemGroup {
            Group {
                switch recorder.session.state {
                case .recording:
                    Button("Close", systemImage: "stop.fill") {
                        perform { try await library.stop(recorder) }
                    }
                    .help("Close timelapse")
                    Button("Pause", systemImage: "pause.fill") {
                        perform { try await library.pause(recorder) }
                    }
                    .help("Pause recording")
                case .paused, .idlePaused:
                    Button("Close", systemImage: "stop.fill") {
                        perform { try await library.stop(recorder) }
                    }
                    .help("Close timelapse")
                    Button("Resume", systemImage: "record.circle") {
                        perform { try await library.record(recorder) }
                    }
                    .buttonStyle(.glassProminent)
                    .help("Resume recording")
                case .finished:
                    Button("Reopen", systemImage: "arrow.uturn.backward.circle") {
                        perform { try library.reopen(recorder) }
                    }
                    .help("Reopen timelapse to keep recording")
                }
            }
            .disabled(isChangingState)
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented { errorMessage = nil }
            }
        )
    }

    private func perform(_ action: @escaping @MainActor () async throws -> Void) {
        isChangingState = true
        Task {
            defer { isChangingState = false }
            do {
                try await action()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
