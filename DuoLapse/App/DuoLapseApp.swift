import SwiftUI

@main
struct DuoLapseApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @AppStorage(AppPreferences.showsMenuBarItemKey) private var showsMenuBarItem = true

    var body: some Scene {
        Window("DuoLapse", id: WindowID.library) {
            if let library = appDelegate.library {
                LibraryView(library: library, navigation: appDelegate.navigation)
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
        }

        MenuBarExtra(isInserted: $showsMenuBarItem) {
            if let library = appDelegate.library {
                MenuBarMenu(library: library, navigation: appDelegate.navigation, updater: appDelegate.updater)
            }
        } label: {
            if let library = appDelegate.library {
                MenuBarLabel(library: library)
            } else {
                Image(systemName: "camera.aperture")
            }
        }

        Settings {
            SettingsView()
        }
    }
}

enum WindowID {
    static let library = "library"
}
