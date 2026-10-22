import AppKit
import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct NewTimelapseView: View {
    let library: TimelapseLibrary
    let onStart: (UUID) -> Void
    @State private var model = NewTimelapseModel()
    @State private var isStarting = false
    @State private var previewer = SourcePreviewer()

    var body: some View {
        Form {
            SourcePreviewSection(screenImage: screenPreview, cameraImage: cameraPreview)
            if !model.capturesScreen && !model.capturesCamera {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Screen and camera recording are both turned off.", systemImage: "info.circle")
                            .foregroundStyle(.secondary)
                        SettingsLink {
                            Text("Choose Sources in Settings…")
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
            if model.capturesScreen || model.capturesCamera {
                Section("Sources") {
                    ScreenSourceRows(model: model)
                    CameraSourceRows(model: model)
                }
            }
            TimingSection(model: model)
            if library.activeRecorder != nil {
                Section {
                    Label("Starting pauses the timelapse that’s recording now.", systemImage: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("New Timelapse")
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
            Task { await model.reloadSourceChoices() }
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
        previewedSources.displayUUID == nil ? nil : previewer.screenImage
    }

    private var cameraPreview: CGImage? {
        guard model.capturesCamera, let cameraID = model.selectedCameraID else { return nil }
        if cameraID == recordingCameraID {
            return library.activeRecorder?.latestPreviews[.camera]
        }
        return previewedSources.cameraID == nil ? nil : previewer.cameraImage
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

private struct SourcePreviewSection: View {
    let screenImage: CGImage?
    let cameraImage: CGImage?

    var body: some View {
        Section {
            SourcesPreview(screenImage: screenImage, cameraImage: cameraImage)
        }
    }
}

private struct ScreenSourceRows: View {
    @Bindable var model: NewTimelapseModel

    var body: some View {
        if model.capturesScreen {
            Group {
                if model.isScreenCaptureAllowed {
                    Picker("Display", selection: $model.selectedDisplayUUID) {
                        ForEach(model.displays) { display in
                            Text(display.name).tag(Optional(display.uuid))
                        }
                    }
                } else {
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
                    Picker("Camera", selection: $model.selectedCameraID) {
                        ForEach(model.cameras) { camera in
                            Text(camera.name).tag(Optional(camera.uniqueID))
                        }
                    }
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

private struct TimingSection: View {
    @Bindable var model: NewTimelapseModel

    var body: some View {
        Section("Timing and Quality") {
            HStack {
                Stepper(value: $model.captureIntervalSeconds, in: 1...300) {
                    LabeledContent("Interval", value: intervalDescription)
                }
                Button("Reset to Default", systemImage: "arrow.counterclockwise", action: model.resetCaptureInterval)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Reset to every \(NewTimelapseModel.defaultCaptureIntervalSeconds) seconds")
                    .disabled(model.isCaptureIntervalDefault)
            }

            Picker("Screen quality", selection: $model.storageResolution) {
                ForEach(StorageResolution.allCases, id: \.self) { resolution in
                    Text(resolution.displayName).tag(resolution)
                }
            }
        }
    }

    private var intervalDescription: String {
        let interval = Duration.seconds(model.captureIntervalSeconds)
        return "Every \(interval.formatted(.units(allowed: [.minutes, .seconds], width: .wide)))"
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

extension StorageResolution {
    fileprivate var displayName: String {
        switch self {
        case .standard: "Standard (1080p)"
        case .high: "High (1440p)"
        }
    }
}
