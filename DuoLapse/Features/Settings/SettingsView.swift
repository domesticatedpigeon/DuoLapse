import DuoLapseCapture
import SwiftUI

struct SettingsView: View {
    @AppStorage(RecordingPreferences.smartPauseKey) private var isSmartPauseEnabled = true
    @AppStorage(RecordingPreferences.keepAwakeKey) private var isKeepAwakeEnabled = true

    var body: some View {
        Form {
            Section("Recording") {
                Toggle(isOn: $isSmartPauseEnabled) {
                    Text("Smart pause")
                    Text("Pause after a minute without keyboard, mouse or trackpad input, and resume when you’re back.")
                }
                Toggle(isOn: $isKeepAwakeEnabled) {
                    Text("Keep awake")
                    Text(
                        "Stop your Mac and webcam from sleeping while a timelapse is recording. The display can still sleep."
                    )
                }
            }

            Section {
                LabeledContent("Version", value: Bundle.main.marketingVersion)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
    }
}

extension Bundle {
    fileprivate var marketingVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
}

#Preview {
    SettingsView()
}
