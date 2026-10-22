import AppKit
import DuoLapseCapture
import DuoLapseCore
import SwiftUI

final class MenuBarStatusItem: NSObject, NSMenuDelegate {

    private let library: TimelapseLibrary
    private let navigation: AppNavigation
    private let updater: AppUpdater
    private var statusItem: NSStatusItem?
    private var displays: [CapturableDisplay] = []
    private var previewRefreshTimer: Timer?
    private weak var refreshingPreview: NSHostingView<MenuSourcesPreview>?
    private weak var refreshingRecorder: TimelapseRecorder?

    init(library: TimelapseLibrary, navigation: AppNavigation, updater: AppUpdater) {
        self.library = library
        self.navigation = navigation
        self.updater = updater
    }

    func setVisible(_ isVisible: Bool) {
        if isVisible, statusItem == nil {
            statusItem = makeStatusItem()
            refreshDisplays()
        } else if !isVisible, let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let library = library
        let navigation = navigation
        refreshDisplays()

        if let focused = library.activeRecorder ?? library.latestPausedRecorder {
            menu.addItem(previewItem(for: focused))
            addSourceSwitchers(for: focused, to: menu)
            menu.addItem(.separator())
        }

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

        menu.addItem(.separator())
        menu.addItem(actionItem("Show Library") { navigation.showLibrary() })
        menu.addItem(actionItem("Settings…", keyEquivalent: ",") { navigation.showSettings() })
        if updater.isAvailable {
            menu.addItem(actionItem("Check for Updates…") { [updater] in updater.checkForUpdates() })
        }
        menu.addItem(.separator())
        menu.addItem(actionItem("Quit DuoLapse", keyEquivalent: "q") { NSApplication.shared.terminate(nil) })
    }

    func menuDidClose(_ menu: NSMenu) {
        previewRefreshTimer?.invalidate()
        previewRefreshTimer = nil
        refreshingPreview = nil
        refreshingRecorder = nil
    }

    private func previewItem(for recorder: TimelapseRecorder) -> NSMenuItem {
        let store = library.store
        Task { await StoredThumbnails.shared.load(for: recorder.session, store: store) }
        let preview = NSHostingView(rootView: MenuSourcesPreview(images: Self.previewImages(of: recorder)))
        preview.frame = NSRect(origin: .zero, size: preview.fittingSize)
        startRefreshing(preview, from: recorder)
        let item = NSMenuItem()
        item.view = preview
        return item
    }

    private func startRefreshing(_ preview: NSHostingView<MenuSourcesPreview>, from recorder: TimelapseRecorder) {
        previewRefreshTimer?.invalidate()
        refreshingPreview = preview
        refreshingRecorder = recorder
        let timer = Timer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(refreshPreview),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        previewRefreshTimer = timer
    }

    @objc private func refreshPreview() {
        guard let preview = refreshingPreview, let recorder = refreshingRecorder else { return }
        let images = Self.previewImages(of: recorder)
        guard images != preview.rootView.images else { return }
        preview.rootView = MenuSourcesPreview(images: images)
    }

    private static func previewImages(of recorder: TimelapseRecorder) -> MenuPreviewImages {
        let thumbnails = StoredThumbnails.shared
        return MenuPreviewImages(
            screen: recorder.latestPreviews[.screen]
                ?? thumbnails.image(for: recorder.session.id, source: .screen),
            camera: recorder.latestPreviews[.camera]
                ?? thumbnails.image(for: recorder.session.id, source: .camera)
        )
    }

    private func addSourceSwitchers(for recorder: TimelapseRecorder, to menu: NSMenu) {
        let library = library
        if let currentDisplayUUID = recorder.session.settings.displayUUID, !displays.isEmpty {
            let choices = displays.map { display in
                MenuChoice(title: display.name, isCurrent: display.uuid == currentDisplayUUID) {
                    Task { try? await library.switchDisplay(of: recorder, to: display.uuid) }
                }
            }
            menu.addItem(submenuItem("Display", choices: choices))
        }
        let cameras = CameraPermission.status == .granted ? CameraCatalog.availableCameras() : []
        if let currentCameraID = recorder.session.settings.cameraID, !cameras.isEmpty {
            let choices = cameras.map { camera in
                MenuChoice(title: camera.name, isCurrent: camera.uniqueID == currentCameraID) {
                    Task { try? await library.switchCamera(of: recorder, to: camera.uniqueID) }
                }
            }
            menu.addItem(submenuItem("Camera", choices: choices))
        }
    }

    private func submenuItem(_ title: String, choices: [MenuChoice]) -> NSMenuItem {
        let submenu = NSMenu(title: title)
        for choice in choices {
            let item = actionItem(choice.title, perform: choice.choose)
            item.state = choice.isCurrent ? .on : .off
            submenu.addItem(item)
        }
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        return item
    }

    private func refreshDisplays() {
        guard ScreenCapturePermission.isGranted else { return }
        Task {
            if let displays = try? await DisplayCatalog.capturableDisplays() {
                self.displays = displays
            }
        }
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
                label.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                label.topAnchor.constraint(equalTo: button.topAnchor),
                label.bottomAnchor.constraint(equalTo: button.bottomAnchor),
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

private struct MenuChoice {
    let title: String
    let isCurrent: Bool
    let choose: () -> Void
}

private struct MenuPreviewImages: Equatable {
    let screen: CGImage?
    let camera: CGImage?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.screen === rhs.screen && lhs.camera === rhs.camera
    }
}

private struct MenuSourcesPreview: View {
    static let width: CGFloat = 300

    let images: MenuPreviewImages

    var body: some View {
        SourcesPreview(screenImage: images.screen, cameraImage: images.camera)
            .frame(width: Self.width)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
    }
}
