import DuoLapseCapture
import DuoLapseCore
import Foundation
import Observation

@Observable
final class NewTimelapseModel {
    static let defaultCaptureIntervalSeconds = 2

    private(set) var isScreenCaptureAllowed = ScreenCapturePermission.isGranted
    private(set) var cameraPermission = CameraPermission.status
    private(set) var displays: [CapturableDisplay] = []
    private(set) var cameras: [CapturableCamera] = []
    var errorMessage: String?

    static let capturesScreenKey = "capture.capturesScreen"
    static let capturesCameraKey = "capture.capturesCamera"

    private(set) var capturesScreen: Bool
    private(set) var capturesCamera: Bool

    var selectedDisplayUUID: String? {
        didSet { defaults.set(selectedDisplayUUID, forKey: PreferenceKey.displayUUID) }
    }

    var selectedCameraID: String? {
        didSet { defaults.set(selectedCameraID, forKey: PreferenceKey.cameraID) }
    }

    var captureIntervalSeconds: Int {
        didSet { defaults.set(captureIntervalSeconds, forKey: PreferenceKey.captureIntervalSeconds) }
    }

    var storageResolution: StorageResolution {
        didSet { defaults.set(storageResolution.rawValue, forKey: PreferenceKey.storageResolution) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.capturesScreen = Self.capturesScreen(in: defaults)
        self.capturesCamera = defaults.bool(forKey: Self.capturesCameraKey)
        self.selectedDisplayUUID = defaults.string(forKey: PreferenceKey.displayUUID)
        self.selectedCameraID = defaults.string(forKey: PreferenceKey.cameraID)
        let storedInterval = defaults.integer(forKey: PreferenceKey.captureIntervalSeconds)
        self.captureIntervalSeconds = storedInterval > 0 ? storedInterval : Self.defaultCaptureIntervalSeconds
        self.storageResolution =
            defaults.string(forKey: PreferenceKey.storageResolution).flatMap { StorageResolution(rawValue: $0) }
            ?? .standard
    }

    var captureSettings: CaptureSettings? {
        guard capturesScreen || capturesCamera else { return nil }
        let screenReady = !capturesScreen || (isScreenCaptureAllowed && selectedDisplayUUID != nil)
        let cameraReady = !capturesCamera || (cameraPermission == .granted && selectedCameraID != nil)
        guard screenReady, cameraReady else { return nil }
        return CaptureSettings(
            captureIntervalSeconds: captureIntervalSeconds,
            storageResolution: storageResolution,
            displayUUID: capturesScreen ? selectedDisplayUUID : nil,
            cameraID: capturesCamera ? selectedCameraID : nil
        )
    }

    func reloadSourceChoices() async {
        let storedCapturesScreen = Self.capturesScreen(in: defaults)
        let storedCapturesCamera = defaults.bool(forKey: Self.capturesCameraKey)
        guard capturesScreen != storedCapturesScreen || capturesCamera != storedCapturesCamera else { return }
        capturesScreen = storedCapturesScreen
        capturesCamera = storedCapturesCamera
        await refreshDevicesAndPermissions()
    }

    private static func capturesScreen(in defaults: UserDefaults) -> Bool {
        defaults.object(forKey: capturesScreenKey) as? Bool ?? true
    }

    var isCaptureIntervalDefault: Bool {
        captureIntervalSeconds == Self.defaultCaptureIntervalSeconds
    }

    func resetCaptureInterval() {
        captureIntervalSeconds = Self.defaultCaptureIntervalSeconds
    }

    func refreshDevicesAndPermissions() async {
        isScreenCaptureAllowed = ScreenCapturePermission.isGranted
        cameraPermission = CameraPermission.status
        if isScreenCaptureAllowed {
            await loadDisplays()
        }
        if cameraPermission == .granted {
            loadCameras()
        }
    }

    func requestScreenCaptureAccess() {
        ScreenCapturePermission.requestOrOpenSystemSettings(defaults: defaults)
    }

    func requestCameraAccess() async {
        switch cameraPermission {
        case .notDetermined:
            cameraPermission = await CameraPermission.request()
            if cameraPermission == .granted {
                loadCameras()
            }
        case .denied:
            CameraPermission.openSystemSettings()
        case .granted:
            break
        }
    }

    private func loadDisplays() async {
        do {
            displays = try await DisplayCatalog.capturableDisplays()
            if !displays.contains(where: { $0.uuid == selectedDisplayUUID }) {
                selectedDisplayUUID = displays.first?.uuid
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadCameras() {
        cameras = CameraCatalog.availableCameras()
        if !cameras.contains(where: { $0.uniqueID == selectedCameraID }) {
            selectedCameraID = cameras.first?.uniqueID
        }
    }
}

private enum PreferenceKey {
    static let displayUUID = "capture.displayUUID"
    static let cameraID = "capture.cameraID"
    static let captureIntervalSeconds = "capture.intervalSeconds"
    static let storageResolution = "capture.storageResolution"
}
