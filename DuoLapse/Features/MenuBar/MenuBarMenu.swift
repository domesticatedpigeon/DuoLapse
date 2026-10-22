import AppKit
import DuoLapseCapture
import SwiftUI

struct MenuBarMenu: View {
    let library: TimelapseLibrary
    let navigation: AppNavigation
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if let active = library.activeRecorder {
            Text("Recording \(active.session.title)")
            Button("Pause Recording") {
                perform { try await library.pause(active) }
            }
            Button("Close Timelapse") {
                perform { try await library.stop(active) }
            }
        } else if let paused = library.latestPausedRecorder {
            Button("Resume \(paused.session.title)") {
                perform { try await library.record(paused) }
            }
        }

        Button("New Timelapse…") {
            navigation.selection = .newTimelapse
            showLibrary()
        }

        if let exportable = library.latestExportableRecorder {
            Button("Export \(exportable.session.title)…") {
                navigation.requestExport(of: exportable.session.id)
                showLibrary()
            }
        }

        Divider()

        Button("Show DuoLapse") {
            showLibrary()
        }
        SettingsLink {
            Text("Settings…")
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit DuoLapse") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func showLibrary() {
        openWindow(id: WindowID.library)
        NSApplication.shared.activate()
    }

    private func perform(_ action: @escaping @MainActor () async throws -> Void) {
        Task { try? await action() }
    }
}
