import SwiftUI

@main
struct DuoLapseApp: App {
    var body: some Scene {
        Window("Library", id: "library") {
            LibraryView()
        }

        Settings {
            SettingsView()
        }
    }
}
