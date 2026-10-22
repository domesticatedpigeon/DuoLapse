import AppKit
import Observation

@Observable
final class AppPreferences {
    private static let showsMenuBarItemKey = "appearance.showsMenuBarItem"
    private static let showsDockIconKey = "appearance.showsDockIcon"

    var showsMenuBarItem: Bool {
        didSet {
            defaults.set(showsMenuBarItem, forKey: Self.showsMenuBarItemKey)
            onShowsMenuBarItemChange?(showsMenuBarItem)
        }
    }

    @ObservationIgnored var onShowsMenuBarItemChange: ((Bool) -> Void)?

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

    func applyDockIconVisibility() {
        NSApplication.shared.setActivationPolicy(showsDockIcon ? .regular : .accessory)
    }
}
