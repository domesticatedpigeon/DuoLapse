import AppKit
import DuoLapseCapture
import SwiftUI

struct LibraryView: View {
    let library: TimelapseLibrary
    @Bindable var navigation: AppNavigation
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @Environment(\.accessibilityReduceMotion) private var reducesMotion
    @State private var renamingID: UUID?
    @State private var trashCandidate: TimelapseRecorder?
    @State private var errorMessage: String?

    var body: some View {
        NavigationSplitView {
            List(selection: $navigation.selection) {
                if isDrafting || !library.openRecorders.isEmpty {
                    Section("Open") {
                        if isDrafting {
                            DraftTimelapseRow()
                                .tag(LibrarySelection.newTimelapse)
                        }
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
            .animation(listAnimation, value: isDrafting)
            .animation(listAnimation, value: sidebarLayout)
            .contextMenu(forSelectionType: LibrarySelection.self, menu: contextMenu(for:)) { selection in
                if let recorder = singleRecorder(in: selection) {
                    beginRenaming(recorder)
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 320)
            .onDeleteCommand {
                switch navigation.selection {
                case .timelapse(let id):
                    trashCandidate = library.recorder(for: id)
                case .newTimelapse, nil:
                    break
                }
            }
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
                .navigationSplitViewColumnWidth(min: 460, ideal: 640)
                .toolbar {
                    if navigation.selection != .newTimelapse {
                        ToolbarItem(placement: .primaryAction) {
                            Button("New Timelapse", systemImage: "plus", action: navigation.showNewTimelapse)
                                .fontWeight(.semibold)
                                .help("New Timelapse")
                        }
                    }
                }
        }
        .frame(minWidth: 800, minHeight: 520)
        .task {
            library.reload()
        }
        .onAppear {
            navigation.openWindowAction = openWindow
            navigation.openSettingsAction = openSettings
            if let active = library.activeRecorder {
                navigation.show(active.session.id)
            }
        }
        .onChange(of: navigation.selection, initial: true) { _, selection in
            if selection == nil {
                navigation.selection = .newTimelapse
            }
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

    private var listAnimation: Animation? {
        reducesMotion ? nil : .smooth(duration: 0.3)
    }

    private var sidebarLayout: [String] {
        library.openRecorders.map { "open-\($0.session.id)" }
            + library.closedRecorders.map { "closed-\($0.session.id)" }
    }

    private var isDrafting: Bool {
        navigation.selection == .newTimelapse
    }

    private func row(for recorder: TimelapseRecorder) -> some View {
        TimelapseRow(
            recorder: recorder,
            store: library.store,
            isRenaming: renamingID == recorder.session.id,
            onRename: { name in finishRenaming(recorder, to: name) },
            onCancelRename: { renamingID = nil }
        )
        .tag(LibrarySelection.timelapse(recorder.session.id))
    }

    @ViewBuilder
    private func contextMenu(for selection: Set<LibrarySelection>) -> some View {
        if let recorder = singleRecorder(in: selection) {
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

    private func singleRecorder(in selection: Set<LibrarySelection>) -> TimelapseRecorder? {
        guard selection.count == 1, case .timelapse(let id) = selection.first else { return nil }
        return library.recorder(for: id)
    }

    private func beginRenaming(_ recorder: TimelapseRecorder) {
        renamingID = recorder.session.id
    }

    private func finishRenaming(_ recorder: TimelapseRecorder, to name: String) {
        guard renamingID == recorder.session.id else { return }
        renamingID = nil
        guard name != recorder.session.title else { return }
        perform { try library.rename(recorder, to: name) }
    }

    private func showInFinder(_ recorder: TimelapseRecorder) {
        NSWorkspace.shared.activateFileViewerSelecting([library.store.directory(for: recorder.session.id)])
    }

    private func moveToTrash(_ recorder: TimelapseRecorder) {
        let wasSelected = navigation.selection == .timelapse(recorder.session.id)
        perform {
            try await library.moveToTrash(recorder)
            if wasSelected {
                navigation.selection = nil
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
                TimelapseDetailView(library: library, navigation: navigation, recorder: recorder)
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
