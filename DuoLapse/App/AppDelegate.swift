import AppKit
import DuoLapseCapture
import DuoLapseCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    let navigation = AppNavigation()
    let updater = AppUpdater()
    let preferences = AppPreferences()
    let library: TimelapseLibrary? = {
        guard let store = try? SessionStore.inApplicationSupport() else { return nil }
        return TimelapseLibrary(store: store)
    }()

    private var supervisionTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        preferences.applyDockIconVisibility()
        guard let library else { return }
        library.reload()
        if let interrupted = library.interruptedRecorder {
            navigation.show(interrupted.session.id)
        }
        RecordingCommands(library: library, navigation: navigation).registerShortcuts()
        supervisionTask = Task {
            await library.superviseRecording()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let library, library.hasRecordingInProgress else { return .terminateNow }
        Task {
            await library.pauseAllForTermination()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
