import DuoLapseCapture
import Observation

@Observable
final class CaptureDevices {
    static let shared = CaptureDevices()

    private(set) var displays: [CapturableDisplay] = []
    private(set) var cameras: [CapturableCamera] = []

    func refresh() async {
        if ScreenCapturePermission.isGranted, let available = try? await DisplayCatalog.capturableDisplays() {
            displays = available
        }
        if CameraPermission.status == .granted {
            cameras = CameraCatalog.availableCameras()
        }
    }
}
