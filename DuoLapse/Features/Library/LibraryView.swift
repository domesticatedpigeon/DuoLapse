import DuoLapseCapture
import SwiftUI

enum LibrarySelection: Hashable {
    case newTimelapse
    case timelapse(UUID)
}

struct LibraryView: View {
    let library: TimelapseLibrary
    @State private var selection: LibrarySelection? = .newTimelapse

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("New Timelapse", systemImage: "plus.circle")
                    .tag(LibrarySelection.newTimelapse)

                if !library.openRecorders.isEmpty {
                    Section("Open") {
                        ForEach(library.openRecorders, id: \.session.id) { recorder in
                            TimelapseRow(recorder: recorder, store: library.store)
                                .tag(LibrarySelection.timelapse(recorder.session.id))
                        }
                    }
                }

                if !library.closedRecorders.isEmpty {
                    Section("Closed") {
                        ForEach(library.closedRecorders, id: \.session.id) { recorder in
                            TimelapseRow(recorder: recorder, store: library.store)
                                .tag(LibrarySelection.timelapse(recorder.session.id))
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        } detail: {
            detail
        }
        .frame(minWidth: 760, minHeight: 520)
        .task {
            library.reload()
            if let interrupted = library.interruptedRecorder {
                selection = .timelapse(interrupted.session.id)
            }
        }
        .task {
            await library.superviseRecording()
        }
        .alert(
            "Resume Recording?",
            isPresented: isShowingInterruption,
            presenting: library.interruptedRecorder
        ) { recorder in
            Button("Resume") {
                library.dismissInterruptedRecording()
                Task { try? await library.record(recorder) }
            }
            Button("Not Now", role: .cancel) {
                library.dismissInterruptedRecording()
            }
        } message: { recorder in
            Text(
                "DuoLapse quit while recording the timelapse from \(recorder.session.title). Frames up to that moment are saved."
            )
        }
    }

    private var isShowingInterruption: Binding<Bool> {
        Binding(
            get: { library.interruptedRecorder != nil },
            set: { isPresented in
                if !isPresented { library.dismissInterruptedRecording() }
            }
        )
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .timelapse(let id):
            if let recorder = library.recorder(for: id) {
                TimelapseDetailView(library: library, recorder: recorder) {
                    selection = .newTimelapse
                }
                .id(id)
            } else {
                ContentUnavailableView("Timelapse Not Found", systemImage: "questionmark.folder")
            }
        case .newTimelapse, nil:
            NewTimelapseView(library: library) { id in
                selection = .timelapse(id)
            }
        }
    }
}
