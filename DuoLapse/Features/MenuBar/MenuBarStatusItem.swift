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
            menu.addItem(informationItem("Recording \(active.session.title)"))
            menu.addItem(actionItem("Pause Recording") { Task { try? await library.pause(active) } })
            menu.addItem(actionItem("Close Timelapse") { Task { try? await library.stop(active) } })
        } else if let paused = library.latestPausedRecorder {
            menu.addItem(
                actionItem("Resume \(paused.session.title)") { Task { try? await library.record(paused) } }
            )
        }

        menu.addItem(
            actionItem("New Timelapse…") {
                navigation.selection = .newTimelapse
                navigation.showLibrary()
            }
        )
        if let exportable = library.latestExportableRecorder {
            menu.addItem(
                actionItem("Export \(exportable.session.title)…") {
                    navigation.requestExport(of: exportable.session.id)
                    navigation.showLibrary()
                }
            )
        }

        menu.addItem(.separator())
        menu.addItem(actionItem("Show DuoLapse") { navigation.showLibrary() })
        menu.addItem(actionItem("Settings…", keyEquivalent: ",") { navigation.showSettings() })
        if updater.isAvailable {
            menu.addItem(actionItem("Check for Updates…") { [updater] in updater.checkForUpdates() })
        }
        menu.addItem(.separator())
        menu.addItem(actionItem("Quit DuoLapse", keyEquivalent: "q") { NSApplication.shared.terminate(nil) })
    }

    private func actionItem(_ title: String, keyEquivalent: String = "", perform: @escaping () -> Void) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(performMenuAction(_:)), keyEquivalent: keyEquivalent)
        item.target = self
        item.representedObject = MenuAction(perform: perform)
        return item
    }

    private func informationItem(_ title: String) -> NSMenuItem {
        NSMenuItem(title: title, action: nil, keyEquivalent: "")
    }

    @objc private func performMenuAction(_ sender: NSMenuItem) {
        (sender.representedObject as? MenuAction)?.perform()
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

private final class MenuAction {
    let perform: () -> Void

    init(perform: @escaping () -> Void) {
        self.perform = perform
    }
}
