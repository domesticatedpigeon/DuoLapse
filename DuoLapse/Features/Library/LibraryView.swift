import DuoLapseCapture
import SwiftUI

struct LibraryView: View {
    let library: TimelapseLibrary
    @Bindable var navigation: AppNavigation
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        NavigationSplitView {
            List(selection: $navigation.selection) {
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
            .toolbar {
                ToolbarItem {
                    SettingsLink {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .help("Settings")
                }
            }
        } detail: {
            detail
        }
        .frame(minWidth: 760, minHeight: 520)
        .task {
            library.reload()
        }
        .onAppear {
            navigation.openWindowAction = openWindow
            navigation.openSettingsAction = openSettings
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
        switch navigation.selection {
        case .timelapse(let id):
            if let recorder = library.recorder(for: id) {
                TimelapseDetailView(library: library, navigation: navigation, recorder: recorder) {
                    navigation.selection = .newTimelapse
                }
                .id(id)
            } else {
                ContentUnavailableView("Timelapse Not Found", systemImage: "questionmark.folder")
            }
        case .newTimelapse, nil:
            NewTimelapseView(library: library) { id in
                navigation.show(id)
            }
        }
    }
}
