import AppKit
import CoreGraphics

public enum ScreenCapturePermission {
    public static var isGranted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    @discardableResult
    public static func request() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    public static func requestOrOpenSystemSettings(defaults: UserDefaults = .standard) {
        if defaults.bool(forKey: hasRequestedKey) {
            openSystemSettings()
        } else {
            defaults.set(true, forKey: hasRequestedKey)
            request()
        }
    }

    private static let hasRequestedKey = "permissions.hasRequestedScreenCapture"

    public static func openSystemSettings() {
        guard
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
        else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
