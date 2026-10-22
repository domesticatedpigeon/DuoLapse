import AppKit
import DuoLapseCapture
import KeyboardShortcuts
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    let preferences: AppPreferences
    @State private var selection: SettingsPane? = .general
    @State private var searchText = ""

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: Self.sidebarWidth)
            Divider()
                .ignoresSafeArea()
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle((selection ?? .general).title)
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .frame(width: 600)
        .frame(minHeight: 440, idealHeight: 500)
    }

    private static let sidebarWidth: CGFloat = 220

    private var sidebar: some View {
        VStack(spacing: 8) {
            SettingsSearchField(text: $searchText)
                .padding(.horizontal, 10)
            List(matchingPanes, selection: $selection) { pane in
                Label(pane.title, systemImage: pane.symbolName)
                    .tag(pane)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .padding(.top, 8)
        .background(.regularMaterial)
    }

    private var detail: some View {
        Group {
            switch selection ?? .general {
            case .general: GeneralSettings(preferences: preferences)
            case .recording: RecordingSettings()
            case .export: ExportFileSettings()
            case .shortcuts: ShortcutSettings()
            case .permissions: PermissionSettings()
            }
        }
        .defaultScrollAnchor(.top)
        .scrollBounceBehavior(.basedOnSize)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) {
            Text((selection ?? .general).title)
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var matchingPanes: [SettingsPane] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return SettingsPane.allCases }
        return SettingsPane.allCases.filter { pane in
            ([pane.title] + pane.keywords).contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

private struct SettingsSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Search", text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button("Clear Search", systemImage: "xmark.circle.fill") { text = "" }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.quaternary, in: .capsule)
    }
}

enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case recording
    case export
    case shortcuts
    case permissions

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "General"
        case .recording: "Recording"
        case .export: "Export"
        case .shortcuts: "Shortcuts"
        case .permissions: "Permissions"
        }
    }

    var symbolName: String {
        switch self {
        case .general: "gearshape"
        case .recording: "record.circle"
        case .export: "square.and.arrow.up"
        case .shortcuts: "keyboard"
        case .permissions: "lock.shield"
        }
    }

    var keywords: [String] {
        switch self {
        case .general: ["login", "startup", "menu bar", "dock", "version"]
        case .recording: ["interval", "quality", "resolution", "smart pause", "idle", "keep awake", "sleep", "webcam"]
        case .export: ["format", "hevc", "h.264", "folder", "file name", "save"]
        case .shortcuts: ["keyboard", "hotkey", "start", "pause"]
        case .permissions:
            ["sources", "record screen", "record camera", "screen recording", "camera", "privacy", "access"]
        }
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
    @State private var captureModel = NewTimelapseModel()

    var body: some View {
        Form {
            CaptureTimingSection(model: captureModel)
            Section {
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
        }
        .formStyle(.grouped)
    }
}

private struct PermissionSettings: View {
    @State private var isScreenCaptureAllowed = ScreenCapturePermission.isGranted
    @State private var cameraPermission = CameraPermission.status
    @AppStorage(NewTimelapseModel.capturesScreenKey) private var capturesScreen = true
    @AppStorage(NewTimelapseModel.capturesCameraKey) private var capturesCamera = false

    var body: some View {
        Form {
            Section("Screen") {
                Toggle(isOn: $capturesScreen) {
                    Text("Record screen")
                    Text("Include a display in new timelapses.")
                }
                PermissionRow(
                    title: "Screen Recording access",
                    detail: isScreenCaptureAllowed
                        ? "Needed to record your screen."
                        : "Needed to record your screen. After allowing it in System Settings, quit and reopen DuoLapse.",
                    isGranted: isScreenCaptureAllowed,
                    actionTitle: "Allow…",
                    action: { ScreenCapturePermission.requestOrOpenSystemSettings() }
                )
            }

            Section("Camera") {
                Toggle(isOn: $capturesCamera) {
                    Text("Record camera")
                    Text("Include a webcam in new timelapses.")
                }
                .onChange(of: capturesCamera) { _, isEnabled in
                    if isEnabled, cameraPermission == .notDetermined {
                        requestCameraAccess()
                    }
                }
                PermissionRow(
                    title: "Camera access",
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
            KeyboardShortcuts.Recorder("Start or pause recording", name: .toggleRecording)
            Text(
                "Works from any app. While recording, it pauses. Otherwise it resumes your latest paused timelapse, or starts a new one with your last settings."
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
