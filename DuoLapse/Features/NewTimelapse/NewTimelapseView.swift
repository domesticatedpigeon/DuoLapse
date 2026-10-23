import AppKit
import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct NewTimelapseView: View {
    let library: TimelapseLibrary
    let onStart: (UUID) -> Void
    @State private var model = NewTimelapseModel()
    @State private var isStarting = false
    @State private var previewer = SourcePreviewer.shared

    var body: some View {
        Form {
            Section {
                SourcesPreview(
                    screenImage: screenPreview,
                    cameraImage: cameraPreview,
                    screenChoices: displayChoices,
                    cameraChoices: cameraChoices
                )
            }
            if !model.capturesScreen && !model.capturesCamera {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Screen and camera recording are both turned off.", systemImage: "info.circle")
                            .foregroundStyle(.secondary)
                        SettingsLink {
                            Text("Choose Sources in Settings…")
                        }
                        .buttonStyle(.glass)
                        .untinted()
                    }
                }
            }
            if needsSourceNotice {
                Section("Sources") {
                    ScreenSourceRows(model: model)
                    CameraSourceRows(model: model)
                }
            }
            if library.activeRecorder != nil {
                Section {
                    Label("Starting pauses the timelapse that’s recording now.", systemImage: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Library")
        .navigationSubtitle("New Timelapse")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Start Recording", systemImage: "record.circle", action: start)
                    .buttonStyle(.glassProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.captureSettings == nil || isStarting)
            }
        }
        .task {
            await model.refreshDevicesAndPermissions()
        }
        .task(id: previewedSources) {
            await previewer.showPreviews(
                displayUUID: previewedSources.displayUUID,
                cameraID: previewedSources.cameraID
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            Task { await model.reloadStoredChoices() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await model.refreshDevicesAndPermissions() }
        }
        .alert("Something Went Wrong", isPresented: isShowingError, presenting: model.errorMessage) { _ in
            Button("OK") {}
        } message: { message in
            Text(message)
        }
    }

    private var previewedSources: PreviewedSources {
        let cameraID =
            model.capturesCamera && model.cameraPermission == .granted && !isStarting ? model.selectedCameraID : nil
        return PreviewedSources(
            displayUUID: model.capturesScreen && model.isScreenCaptureAllowed ? model.selectedDisplayUUID : nil,
            cameraID: cameraID == recordingCameraID ? nil : cameraID
        )
    }

    private var recordingCameraID: String? {
        library.activeRecorder?.session.settings.cameraID
    }

    private var screenPreview: CGImage? {
        previewedSources.displayUUID.flatMap(previewer.screenImage(forDisplay:))
    }

    private var cameraPreview: CGImage? {
        guard model.capturesCamera, let cameraID = model.selectedCameraID else { return nil }
        if cameraID == recordingCameraID {
            return library.activeRecorder?.latestPreviews[.camera]
        }
        return previewedSources.cameraID.flatMap(previewer.cameraImage(forCamera:))
    }

    private var needsSourceNotice: Bool {
        let screenNeedsAttention = model.capturesScreen && !model.isScreenCaptureAllowed
        let cameraNeedsAttention =
            model.capturesCamera && (model.cameraPermission != .granted || model.cameras.isEmpty)
        return screenNeedsAttention || cameraNeedsAttention
    }

    private var displayChoices: [SourceChoice] {
        guard model.capturesScreen, model.isScreenCaptureAllowed else { return [] }
        return model.displays.map { display in
            SourceChoice(id: display.uuid, title: display.name, isSelected: display.uuid == model.selectedDisplayUUID) {
                model.selectedDisplayUUID = display.uuid
            }
        }
    }

    private var cameraChoices: [SourceChoice] {
        guard model.capturesCamera, model.cameraPermission == .granted else { return [] }
        return model.cameras.map { camera in
            SourceChoice(id: camera.uniqueID, title: camera.name, isSelected: camera.uniqueID == model.selectedCameraID)
            {
                model.selectedCameraID = camera.uniqueID
            }
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { isPresented in
                if !isPresented { model.errorMessage = nil }
            }
        )
    }

    private func start() {
        guard let settings = model.captureSettings else { return }
        isStarting = true
        Task {
            defer { isStarting = false }
            await previewer.stopCamera()
            do {
                onStart(try await library.startNewTimelapse(settings: settings))
            } catch {
                model.errorMessage = error.localizedDescription
            }
        }
    }
}

private struct PreviewedSources: Hashable {
    let displayUUID: String?
    let cameraID: String?
}

private struct ScreenSourceRows: View {
    @Bindable var model: NewTimelapseModel

    var body: some View {
        if model.capturesScreen {
            Group {
                if !model.isScreenCaptureAllowed {
                    PermissionNotice(
                        message:
                            "Allow Screen Recording for DuoLapse in System Settings, then quit and reopen DuoLapse.",
                        actionTitle: "Allow Screen Recording",
                        action: model.requestScreenCaptureAccess
                    )
                }
            }
        }
    }
}

private struct CameraSourceRows: View {
    @Bindable var model: NewTimelapseModel

    var body: some View {
        if model.capturesCamera {
            Group {
                switch model.cameraPermission {
                case .granted where model.cameras.isEmpty:
                    Text("No camera found. Connect a camera to record it.")
                        .foregroundStyle(.secondary)
                case .granted:
                    EmptyView()
                case .notDetermined:
                    PermissionNotice(
                        message: "DuoLapse needs access to your camera to record it.",
                        actionTitle: "Allow Camera Access",
                        action: requestCameraAccess
                    )
                case .denied:
                    PermissionNotice(
                        message:
                            "Camera access is turned off. Allow DuoLapse in System Settings to record your camera.",
                        actionTitle: "Open System Settings",
                        action: requestCameraAccess
                    )
                }
            }
        }
    }

    private func requestCameraAccess() {
        Task { await model.requestCameraAccess() }
    }
}

private struct PermissionNotice: View {
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(message, systemImage: "lock")
                .foregroundStyle(.secondary)
            Button(actionTitle, action: action)
        }
    }
}
