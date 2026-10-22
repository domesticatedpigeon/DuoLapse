import AppKit
import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct NewTimelapseView: View {
    let library: TimelapseLibrary
    let onStart: (UUID) -> Void
    @State private var model = NewTimelapseModel()
    @State private var isStarting = false

    var body: some View {
        Form {
            ScreenSourceSection(model: model)
            CameraSourceSection(model: model)
            TimingSection(model: model)
        }
        .formStyle(.grouped)
        .navigationTitle("New Timelapse")
        .safeAreaInset(edge: .bottom) {
            HStack {
                if library.activeRecorder != nil {
                    Text("Starting pauses the timelapse that’s recording now.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Start Recording", systemImage: "record.circle", action: start)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.captureSettings == nil || isStarting)
            }
            .padding()
        }
        .task {
            await model.refreshDevicesAndPermissions()
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
            do {
                onStart(try await library.startNewTimelapse(settings: settings))
            } catch {
                model.errorMessage = error.localizedDescription
            }
        }
    }
}

private struct ScreenSourceSection: View {
    @Bindable var model: NewTimelapseModel

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
    @Bindable var model: NewTimelapseModel

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
    @Bindable var model: NewTimelapseModel

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
