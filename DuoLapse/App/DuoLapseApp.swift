import DuoLapseCapture
import DuoLapseCore
import SwiftUI

@main
struct DuoLapseApp: App {
    @State private var library = Self.makeLibrary()

    var body: some Scene {
        Window("DuoLapse", id: "library") {
            if let library {
                LibraryView(library: library)
            } else {
                ContentUnavailableView(
                    "DuoLapse Can’t Open Its Library",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Check that your Application Support folder is writable, then reopen DuoLapse.")
                )
            }
        }

        Settings {
            SettingsView()
        }
    }

    private static func makeLibrary() -> TimelapseLibrary? {
        guard let store = try? SessionStore.inApplicationSupport() else { return nil }
        return TimelapseLibrary(store: store)
    }
}
