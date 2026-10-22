import AppKit
import Observation
import SwiftUI

enum LibrarySelection: Hashable {
    case newTimelapse
    case timelapse(UUID)
}

@Observable
final class AppNavigation {
    var selection: LibrarySelection? = .newTimelapse
    var exportRequestID: UUID?
    @ObservationIgnored var openWindowAction: OpenWindowAction?
    @ObservationIgnored var openSettingsAction: OpenSettingsAction?

    func show(_ id: UUID) {
        selection = .timelapse(id)
    }

    func requestExport(of id: UUID) {
        selection = .timelapse(id)
        exportRequestID = id
    }

    func showLibrary() {
        NSApplication.shared.activate()
        let libraryWindow = NSApplication.shared.windows.first { window in
            window.identifier?.rawValue.hasPrefix(WindowID.library) == true
        }
        if let libraryWindow {
            libraryWindow.makeKeyAndOrderFront(nil)
        } else {
            openWindowAction?(id: WindowID.library)
        }
    }

    func showNewTimelapse() {
        selection = .newTimelapse
        showLibrary()
    }

    func showSettings() {
        NSApplication.shared.activate()
        openSettingsAction?()
    }
}
