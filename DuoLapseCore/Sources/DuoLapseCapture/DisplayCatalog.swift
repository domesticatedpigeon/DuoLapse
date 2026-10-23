import AppKit
import ColorSync
import DuoLapseCore
@preconcurrency import ScreenCaptureKit

nonisolated public struct CapturableDisplay: Identifiable, Hashable, Sendable {
    public let uuid: String
    public let displayID: CGDirectDisplayID
    public let name: String
    public let pixelSize: PixelSize

    public var id: String {
        uuid
    }
}

public enum DisplayCatalog {
    public static func capturableDisplays() async throws -> [CapturableDisplay] {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        return content.displays.compactMap { display in
            guard let uuid = uuidString(for: display.displayID) else { return nil }
            return CapturableDisplay(
                uuid: uuid,
                displayID: display.displayID,
                name: localizedName(for: display.displayID),
                pixelSize: pixelSize(of: display)
            )
        }
    }

    static func uuidString(for displayID: CGDirectDisplayID) -> String? {
        let unmanagedUUID: Unmanaged<CFUUID>? = CGDisplayCreateUUIDFromDisplayID(displayID)
        guard let uuid = unmanagedUUID?.takeRetainedValue() else { return nil }
        return CFUUIDCreateString(nil, uuid) as String
    }

    static func pixelSize(of display: SCDisplay) -> PixelSize {
        guard let mode = CGDisplayCopyDisplayMode(display.displayID) else {
            return PixelSize(width: display.width, height: display.height)
        }
        return PixelSize(width: mode.pixelWidth, height: mode.pixelHeight)
    }

    private static func localizedName(for displayID: CGDirectDisplayID) -> String {
        let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")
        let screen = NSScreen.screens.first { screen in
            (screen.deviceDescription[screenNumberKey] as? NSNumber)?.uint32Value == displayID
        }
        return screen?.localizedName ?? "Display \(displayID)"
    }
}
