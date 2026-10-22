import AppKit
import DuoLapseCapture
import SwiftUI

struct LibraryView: View {
    let library: TimelapseLibrary
    @Bindable var navigation: AppNavigation
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @State private var renamingRecorder: TimelapseRecorder?
    @State private var proposedName = ""
    @State private var trashCandidate: TimelapseRecorder?
    @State private var errorMessage: String?

    var body: some View {
        NavigationSplitView {
            List(selection: $navigation.selection) {
                Label("New Timelapse", systemImage: "plus.circle")
                    .tag(LibrarySelection.newTimelapse)

                if !library.openRecorders.isEmpty {
                    Section("Open") {
                        ForEach(library.openRecorders, id: \.session.id) { recorder in
                            row(for: recorder)
                        }
                    }
                }

                if !library.closedRecorders.isEmpty {
                    Section("Closed") {
                        ForEach(library.closedRecorders, id: \.session.id) { recorder in
                            row(for: recorder)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 320)
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
                .navigationSplitViewColumnWidth(min: 420, ideal: 640)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button("New Timelapse", systemImage: "plus", action: navigation.showNewTimelapse)
                            .help("New Timelapse")
                            .disabled(navigation.selection == .newTimelapse)
                    }
                }
        }
        .frame(minWidth: 760, minHeight: 520)
        .task {
            library.reload()
        }
        .onAppear {
            navigation.openWindowAction = openWindow
            navigation.openSettingsAction = openSettings
        }
        .alert("Rename Timelapse", isPresented: isRenaming, presenting: renamingRecorder) { recorder in
            TextField("Name", text: $proposedName, prompt: Text(recorder.session.title))
            Button("Rename") {
                perform { try library.rename(recorder, to: proposedName) }
            }
            .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Leave the name empty to use the recording’s start date.")
        }
        .confirmationDialog(
            "Move this timelapse to the Trash?",
            isPresented: isConfirmingTrash,
            titleVisibility: .visible,
            presenting: trashCandidate
        ) { recorder in
            Button("Move to Trash", role: .destructive) {
                moveToTrash(recorder)
            }
        } message: { _ in
            Text("Its recorded frames are deleted when you empty the Trash. Exported videos are kept.")
        }
        .alert("Something Went Wrong", isPresented: isShowingError, presenting: errorMessage) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
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

    private func row(for recorder: TimelapseRecorder) -> some View {
        TimelapseRow(recorder: recorder, store: library.store)
            .tag(LibrarySelection.timelapse(recorder.session.id))
            .contextMenu {
                TimelapseContextMenu(
                    library: library,
                    recorder: recorder,
                    perform: perform,
                    onExport: { navigation.requestExport(of: recorder.session.id) },
                    onRename: { beginRenaming(recorder) },
                    onShowInFinder: { showInFinder(recorder) },
                    onMoveToTrash: { trashCandidate = recorder }
                )
            }
    }

    private func beginRenaming(_ recorder: TimelapseRecorder) {
        proposedName = recorder.session.name ?? ""
        renamingRecorder = recorder
    }

    private func showInFinder(_ recorder: TimelapseRecorder) {
        NSWorkspace.shared.activateFileViewerSelecting([library.store.directory(for: recorder.session.id)])
    }

    private func moveToTrash(_ recorder: TimelapseRecorder) {
        let wasSelected = navigation.selection == .timelapse(recorder.session.id)
        perform {
            try await library.moveToTrash(recorder)
            if wasSelected {
                navigation.selection = .newTimelapse
            }
        }
    }

    private func perform(_ action: @escaping @MainActor () async throws -> Void) {
        Task {
            do {
                try await action()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var isRenaming: Binding<Bool> {
        Binding(
            get: { renamingRecorder != nil },
            set: { isPresented in
                if !isPresented { renamingRecorder = nil }
            }
        )
    }

    private var isConfirmingTrash: Binding<Bool> {
        Binding(
            get: { trashCandidate != nil },
            set: { isPresented in
                if !isPresented { trashCandidate = nil }
            }
        )
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented { errorMessage = nil }
            }
        )
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
