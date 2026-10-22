import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct TimelapseDetailView: View {
    let library: TimelapseLibrary
    let recorder: TimelapseRecorder
    let onDelete: () -> Void
    @State private var isChangingState = false
    @State private var isConfirmingDelete = false
    @State private var isExporting = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                TimelapseThumbnail(session: recorder.session, store: library.store, maximumSide: 960)
                    .aspectRatio(16 / 10, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 8))
            }

            Section("Status") {
                LabeledContent("State", value: recorder.session.state.displayName)
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    LabeledContent(
                        "Recorded time",
                        value: recorder.recordedDuration.formatted(.time(pattern: .hourMinuteSecond))
                    )
                }
                LabeledContent("Size on disk", value: Int64(recorder.bytesOnDisk).formatted(.byteCount(style: .file)))
                if let lastCaptureError = recorder.lastCaptureError {
                    Label(lastCaptureError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Capture") {
                LabeledContent("Sources", value: sourcesDescription)
                LabeledContent("Interval", value: intervalDescription)
                LabeledContent("Frames", value: recorder.session.capturedFrameCount.formatted())
            }
        }
        .formStyle(.grouped)
        .navigationTitle(recorder.session.title)
        .safeAreaInset(edge: .bottom) {
            controls
                .padding()
        }
        .sheet(isPresented: $isExporting) {
            ExportSheet(session: recorder.session, store: library.store)
        }
        .confirmationDialog(
            "Move this timelapse to the Trash?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                perform {
                    try await library.moveToTrash(recorder)
                    onDelete()
                }
            }
        } message: {
            Text("Its recorded frames are deleted when you empty the Trash. Exported videos are kept.")
        }
        .alert("Something Went Wrong", isPresented: isShowingError, presenting: errorMessage) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    private var controls: some View {
        HStack {
            Button("Move to Trash…", systemImage: "trash", role: .destructive) {
                isConfirmingDelete = true
            }
            Button("Export…", systemImage: "square.and.arrow.up") {
                isExporting = true
            }
            .disabled(recorder.isCapturing || recorder.session.capturedFrameCount == 0)

            Spacer()

            switch recorder.session.state {
            case .recording:
                Button("Pause", systemImage: "pause.fill") {
                    perform { try await library.pause(recorder) }
                }
                Button("Close", systemImage: "stop.fill") {
                    perform { try await library.stop(recorder) }
                }
            case .paused, .idlePaused:
                Button("Close", systemImage: "stop.fill") {
                    perform { try await library.stop(recorder) }
                }
                Button("Resume", systemImage: "record.circle") {
                    perform { try await library.record(recorder) }
                }
                .buttonStyle(.borderedProminent)
            case .finished:
                EmptyView()
            }
        }
        .controlSize(.large)
        .disabled(isChangingState)
    }

    private var sourcesDescription: String {
        recorder.session.settings.sources
            .map { $0 == .screen ? "Screen" : "Camera" }
            .formatted(.list(type: .and))
    }

    private var intervalDescription: String {
        let interval = Duration.seconds(recorder.session.settings.captureIntervalSeconds)
        return "Every \(interval.formatted(.units(allowed: [.minutes, .seconds], width: .wide)))"
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
