import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct SourceSwitcherSection: View {
    let library: TimelapseLibrary
    let recorder: TimelapseRecorder
    let onError: (String) -> Void
    @State private var displays: [CapturableDisplay] = []
    @State private var cameras: [CapturableCamera] = []
    @State private var isSwitching = false

    var body: some View {
        if recorder.session.isOpen, !recorder.session.settings.sources.isEmpty {
            Section("Sources") {
                if let displayUUID = recorder.session.settings.displayUUID {
                    Picker("Display", selection: displaySelection(current: displayUUID)) {
                        ForEach(displays) { display in
                            Text(display.name).tag(display.uuid)
                        }
                        if !displays.contains(where: { $0.uuid == displayUUID }) {
                            Text("Unavailable display").tag(displayUUID)
                        }
                    }
                }
                if let cameraID = recorder.session.settings.cameraID {
                    Picker("Camera", selection: cameraSelection(current: cameraID)) {
                        ForEach(cameras) { camera in
                            Text(camera.name).tag(camera.uniqueID)
                        }
                        if !cameras.contains(where: { $0.uniqueID == cameraID }) {
                            Text("Unavailable camera").tag(cameraID)
                        }
                    }
                }
            }
            .disabled(isSwitching)
            .task {
                await loadDevices()
            }
        }
    }

    private func displaySelection(current: String) -> Binding<String> {
        Binding(
            get: { current },
            set: { uuid in switchSource { try await library.switchDisplay(of: recorder, to: uuid) } }
        )
    }

    private func cameraSelection(current: String) -> Binding<String> {
        Binding(
            get: { current },
            set: { id in switchSource { try await library.switchCamera(of: recorder, to: id) } }
        )
    }

    private func switchSource(_ change: @escaping @MainActor () async throws -> Void) {
        isSwitching = true
        Task {
            defer { isSwitching = false }
            do {
                try await change()
            } catch {
                onError(error.localizedDescription)
            }
        }
    }

    private func loadDevices() async {
        if ScreenCapturePermission.isGranted {
            displays = (try? await DisplayCatalog.capturableDisplays()) ?? []
        }
        if CameraPermission.status == .granted {
            cameras = CameraCatalog.availableCameras()
        }
    }
}
