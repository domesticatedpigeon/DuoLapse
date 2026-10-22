import DuoLapseCapture
import KeyboardShortcuts
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    let preferences: AppPreferences

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                GeneralSettings(preferences: preferences)
            }
            Tab("Recording", systemImage: "record.circle") {
                RecordingSettings()
            }
            Tab("Shortcuts", systemImage: "keyboard") {
                ShortcutSettings()
            }
        }
        .frame(width: 480)
        .scenePadding()
    }
}

private struct GeneralSettings: View {
    @Bindable var preferences: AppPreferences
    @State private var opensAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?

    var body: some View {
        Form {
            Section {
                Toggle("Open at login", isOn: $opensAtLogin)
                    .onChange(of: opensAtLogin) { _, isEnabled in
                        updateLoginItem(isEnabled: isEnabled)
                    }
                if let loginItemError {
                    Text(loginItemError)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Toggle(isOn: $preferences.showsMenuBarItem) {
                    Text("Show in menu bar")
                    Text("Shows the recording timer and a quick access menu.")
                }
                .disabled(!preferences.showsDockIcon)
                Toggle(isOn: $preferences.showsDockIcon) {
                    Text("Show in Dock")
                    Text("When hidden, open DuoLapse from the menu bar.")
                }
                .disabled(!preferences.showsMenuBarItem)
            } footer: {
                Text("DuoLapse needs to appear in the menu bar or the Dock, so one of these stays on.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Version", value: Bundle.main.marketingVersion)
            }
        }
        .formStyle(.grouped)
    }

    private func updateLoginItem(isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
        }
        opensAtLogin = SMAppService.mainApp.status == .enabled
        if SMAppService.mainApp.status == .requiresApproval {
            loginItemError = "Allow DuoLapse in System Settings › General › Login Items."
        }
    }
}

private struct RecordingSettings: View {
    @AppStorage(RecordingPreferences.smartPauseKey) private var isSmartPauseEnabled = true
    @AppStorage(RecordingPreferences.keepAwakeKey) private var isKeepAwakeEnabled = true

    var body: some View {
        Form {
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
        .formStyle(.grouped)
    }
}

private struct ShortcutSettings: View {
    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Start or resume recording", name: .startRecording)
            KeyboardShortcuts.Recorder("Pause recording", name: .pauseRecording)
            KeyboardShortcuts.Recorder("Start or pause recording", name: .toggleRecording)
            Text(
                "Shortcuts work from any app. Starting resumes your latest paused timelapse, or starts a new one with your last settings."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}

extension Bundle {
    fileprivate var marketingVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
}

#Preview {
    SettingsView(preferences: AppPreferences())
}
