import SwiftUI

@main
struct DuoLapseApp: App {
    var body: some Scene {
        Window("DuoLapse", id: "recorder") {
            RecorderView()
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }
}
