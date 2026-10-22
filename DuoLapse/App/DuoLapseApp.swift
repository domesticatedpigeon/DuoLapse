import SwiftUI

@main
struct DuoLapseApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Window("DuoLapse", id: "library") {
            if let library = appDelegate.library {
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
}
