import AppKit
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
            Tab("Permissions", systemImage: "lock.shield") {
                PermissionSettings()
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
                Text("DuoLapse needs to appear in the menu bar or the Dock, so one of these stays on.")
                    .font(.callout)
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

private struct PermissionSettings: View {
    @State private var isScreenCaptureAllowed = ScreenCapturePermission.isGranted
    @State private var cameraPermission = CameraPermission.status

    var body: some View {
        Form {
            Section {
                PermissionRow(
                    title: "Screen Recording",
                    detail: isScreenCaptureAllowed
                        ? "Needed to record your screen."
                        : "Needed to record your screen. After allowing it in System Settings, quit and reopen DuoLapse.",
                    isGranted: isScreenCaptureAllowed,
                    actionTitle: "Allow…",
                    action: { ScreenCapturePermission.requestOrOpenSystemSettings() }
                )
                PermissionRow(
                    title: "Camera",
                    detail: "Needed to record your webcam.",
                    isGranted: cameraPermission == .granted,
                    actionTitle: cameraPermission == .notDetermined ? "Allow…" : "Open System Settings…",
                    action: requestCameraAccess
                )
            }
        }
        .formStyle(.grouped)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refresh()
        }
        .onAppear(perform: refresh)
    }

    private func refresh() {
        isScreenCaptureAllowed = ScreenCapturePermission.isGranted
        cameraPermission = CameraPermission.status
    }

    private func requestCameraAccess() {
        if cameraPermission == .notDetermined {
            Task { cameraPermission = await CameraPermission.request() }
        } else {
            CameraPermission.openSystemSettings()
        }
    }
}

private struct PermissionRow: View {
    let title: String
    let detail: String
    let isGranted: Bool
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        LabeledContent {
            if isGranted {
                Label("Allowed", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button(actionTitle, action: action)
                    .buttonStyle(.glass)
            }
        } label: {
            Text(title)
            Text(detail)
        }
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
