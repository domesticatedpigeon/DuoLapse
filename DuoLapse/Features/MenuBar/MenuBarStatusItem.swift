import AppKit
import DuoLapseCapture
import SwiftUI

final class MenuBarStatusItem: NSObject, NSMenuDelegate {
    private let library: TimelapseLibrary
    private let navigation: AppNavigation
    private let updater: AppUpdater
    private var statusItem: NSStatusItem?

    init(library: TimelapseLibrary, navigation: AppNavigation, updater: AppUpdater) {
        self.library = library
        self.navigation = navigation
        self.updater = updater
    }

    func setVisible(_ isVisible: Bool) {
        if isVisible, statusItem == nil {
            statusItem = makeStatusItem()
        } else if !isVisible, let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let library = library
        let navigation = navigation

        if let active = library.activeRecorder {
            menu.addItem(InformationMenuItem(title: "Recording \(active.session.title)"))
            menu.addItem(ActionMenuItem(title: "Pause Recording") { Task { try? await library.pause(active) } })
            menu.addItem(ActionMenuItem(title: "Close Timelapse") { Task { try? await library.stop(active) } })
        } else if let paused = library.latestPausedRecorder {
            menu.addItem(
                ActionMenuItem(title: "Resume \(paused.session.title)") { Task { try? await library.record(paused) } }
            )
        }

        menu.addItem(
            ActionMenuItem(title: "New Timelapse…") {
                navigation.selection = .newTimelapse
                navigation.showLibrary()
            }
        )
        if let exportable = library.latestExportableRecorder {
            menu.addItem(
                ActionMenuItem(title: "Export \(exportable.session.title)…") {
                    navigation.requestExport(of: exportable.session.id)
                    navigation.showLibrary()
                }
            )
        }

        menu.addItem(.separator())
        menu.addItem(ActionMenuItem(title: "Show DuoLapse") { navigation.showLibrary() })
        menu.addItem(ActionMenuItem(title: "Settings…", keyEquivalent: ",") { navigation.showSettings() })
        if updater.isAvailable {
            menu.addItem(ActionMenuItem(title: "Check for Updates…") { [updater] in updater.checkForUpdates() })
        }
        menu.addItem(.separator())
        menu.addItem(ActionMenuItem(title: "Quit DuoLapse", keyEquivalent: "q") { NSApplication.shared.terminate(nil) })
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        if let button = item.button {
            let label = PassthroughHostingView(
                rootView: MenuBarLabel(library: library) { [weak item] width in
                    item?.length = width
                }
            )
            label.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            ])
        }
        return item
    }
}

private final class PassthroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

private final class ActionMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(title: String, keyEquivalent: String = "", handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(performHandler), keyEquivalent: keyEquivalent)
        target = self
    }

    required init(coder: NSCoder) {
        fatalError("ActionMenuItem is created in code only")
    }

    @objc private func performHandler() {
        handler()
    }
}

private final class InformationMenuItem: NSMenuItem {
    init(title: String) {
        super.init(title: title, action: nil, keyEquivalent: "")
        isEnabled = false
    }

    required init(coder: NSCoder) {
        fatalError("InformationMenuItem is created in code only")
    }
}
