import DuoLapseCapture
import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self(
        "toggleRecording", default: .init(.r, modifiers: [.control, .option, .command]))
}

struct RecordingCommands {
    let library: TimelapseLibrary
    let navigation: AppNavigation

    func registerShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .toggleRecording) {
            Task { @MainActor in
                do {
                    try await toggle()
                } catch {
                    navigation.showLibrary()
                }
            }
        }
    }

    func startOrResume() async throws {
        guard library.activeRecorder == nil else { return }
        if let paused = library.latestPausedRecorder {
            try await library.record(paused)
            navigation.show(paused.session.id)
        } else if let settings = NewTimelapseModel().captureSettings {
            navigation.show(try await library.startNewTimelapse(settings: settings))
        } else {
            navigation.showNewTimelapse()
        }
    }

    func pause() async throws {
        guard let active = library.activeRecorder else { return }
        try await library.pause(active)
    }

    func toggle() async throws {
        if library.activeRecorder != nil {
            try await pause()
        } else {
            try await startOrResume()
        }
    }
}
