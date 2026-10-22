import AppKit
import DuoLapseCapture
import DuoLapseCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    let library: TimelapseLibrary? = {
        guard let store = try? SessionStore.inApplicationSupport() else { return nil }
        return TimelapseLibrary(store: store)
    }()

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let library, library.hasRecordingInProgress else { return .terminateNow }
        Task {
            await library.pauseAllForTermination()
            sender.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
