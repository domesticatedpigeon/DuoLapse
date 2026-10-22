import AppKit

enum AppPreferences {
    static let showsMenuBarItemKey = "appearance.showsMenuBarItem"
    static let showsDockIconKey = "appearance.showsDockIcon"

    static var showsDockIcon: Bool {
        UserDefaults.standard.object(forKey: showsDockIconKey) as? Bool ?? true
    }

    static func applyDockIconVisibility(_ showsDockIcon: Bool) {
        NSApplication.shared.setActivationPolicy(showsDockIcon ? .regular : .accessory)
    }
}
