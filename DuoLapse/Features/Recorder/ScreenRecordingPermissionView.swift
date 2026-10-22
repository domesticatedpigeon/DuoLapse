import AppKit
import SwiftUI

struct ScreenRecordingPermissionView: View {
    let onRequestAccess: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Screen Recording Access Needed", systemImage: "rectangle.dashed.badge.record")
        } description: {
            Text(
                "DuoLapse takes a screenshot of your chosen display at each interval. Allow DuoLapse in System Settings, then quit and reopen it."
            )
        } actions: {
            Button("Allow Screen Recording", action: onRequestAccess)
                .buttonStyle(.borderedProminent)
            Button("Quit DuoLapse") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

#Preview {
    ScreenRecordingPermissionView {}
}
