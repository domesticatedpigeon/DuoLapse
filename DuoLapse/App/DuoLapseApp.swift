import SwiftUI

@main
struct DuoLapseApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Window("DuoLapse", id: WindowID.library) {
            if let library = appDelegate.library {
                LibraryView(library: library, navigation: appDelegate.navigation)
                    .tint(.brandPink)
            } else {
                ContentUnavailableView(
                    "DuoLapse Can’t Open Its Library",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Check that your Application Support folder is writable, then reopen DuoLapse.")
                )
            }
        }

        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesButton(updater: appDelegate.updater)
            }
            CommandGroup(replacing: .newItem) {
                Button("New Timelapse", action: appDelegate.navigation.showNewTimelapse)
                    .keyboardShortcut("n")
            }
        }

        Settings {
            SettingsView(preferences: appDelegate.preferences)
                .tint(.brandPink)
        }
    }
}

enum WindowID {
    static let library = "library"
}
