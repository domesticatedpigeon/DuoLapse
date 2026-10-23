import Foundation

public enum RecordingPreferences {
    public static let smartPauseKey = "recording.smartPause"
    public static let keepAwakeKey = "recording.keepAwake"

    public static var isSmartPauseEnabled: Bool {
        UserDefaults.standard.object(forKey: smartPauseKey) as? Bool ?? true
    }

    public static var isKeepAwakeEnabled: Bool {
        UserDefaults.standard.object(forKey: keepAwakeKey) as? Bool ?? true
    }
}
