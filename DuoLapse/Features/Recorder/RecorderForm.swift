import DuoLapseCore
import SwiftUI

struct RecorderForm: View {
    @Bindable var model: RecorderModel

    var body: some View {
        Form {
            Group {
                ScreenSourceSection(model: model)
                CameraSourceSection(model: model)
                TimingSection(model: model)
            }
            .disabled(!model.canEditSettings)

            if let recorder = model.recorder {
                RecordingStatusSection(recorder: recorder)
            }
        }
        .formStyle(.grouped)
        .safeAreaInset(edge: .bottom) {
            RecorderControls(model: model)
                .padding()
        }
    }
}

private struct ScreenSourceSection: View {
    @Bindable var model: RecorderModel

    var body: some View {
        Section("Screen") {
            Toggle("Record screen", isOn: $model.capturesScreen)
            if model.capturesScreen {
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

private struct CameraSourceSection: View {
    @Bindable var model: RecorderModel

    var body: some View {
        Section("Camera") {
            Toggle("Record camera", isOn: $model.capturesCamera)
            if model.capturesCamera {
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
    @Bindable var model: RecorderModel

    var body: some View {
        Section("Timing and Quality") {
            Stepper(value: $model.captureIntervalSeconds, in: 1...300) {
                LabeledContent("Interval", value: intervalDescription)
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
