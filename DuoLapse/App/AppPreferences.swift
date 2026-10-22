import AppKit
import Observation

@Observable
final class AppPreferences {
    private static let showsMenuBarItemKey = "appearance.showsMenuBarItem"
    private static let showsDockIconKey = "appearance.showsDockIcon"

    var showsMenuBarItem: Bool {
        didSet { defaults.set(showsMenuBarItem, forKey: Self.showsMenuBarItemKey) }
    }

    var showsDockIcon: Bool {
        didSet {
            defaults.set(showsDockIcon, forKey: Self.showsDockIconKey)
            applyDockIconVisibility()
        }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showsMenuBarItem = defaults.object(forKey: Self.showsMenuBarItemKey) as? Bool ?? true
        showsDockIcon = defaults.object(forKey: Self.showsDockIconKey) as? Bool ?? true
    }

    var isMenuBarItemInserted: Bool {
        get { showsMenuBarItem }
        set {
            if newValue != showsMenuBarItem {
                showsMenuBarItem = newValue
            }
        }
    }

    func applyDockIconVisibility() {
        NSApplication.shared.setActivationPolicy(showsDockIcon ? .regular : .accessory)
    }
}
