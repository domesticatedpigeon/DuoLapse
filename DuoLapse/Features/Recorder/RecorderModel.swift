import DuoLapseCapture
import DuoLapseCore
import Foundation
import Observation

@Observable
final class RecorderModel {
    private(set) var isScreenCaptureAllowed = ScreenCapturePermission.isGranted
    private(set) var displays: [CapturableDisplay] = []
    private(set) var recorder: TimelapseRecorder?
    private(set) var isChangingState = false
    var errorMessage: String?

    var selectedDisplayUUID: String? {
        didSet { defaults.set(selectedDisplayUUID, forKey: PreferenceKey.displayUUID) }
    }

    var captureIntervalSeconds: Int {
        didSet { defaults.set(captureIntervalSeconds, forKey: PreferenceKey.captureIntervalSeconds) }
    }

    var storageResolution: StorageResolution {
        didSet { defaults.set(storageResolution.rawValue, forKey: PreferenceKey.storageResolution) }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let store: SessionStore?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.store = try? SessionStore.inApplicationSupport()
        self.selectedDisplayUUID = defaults.string(forKey: PreferenceKey.displayUUID)
        let storedInterval = defaults.integer(forKey: PreferenceKey.captureIntervalSeconds)
        self.captureIntervalSeconds = storedInterval > 0 ? storedInterval : 5
        self.storageResolution =
            defaults.string(forKey: PreferenceKey.storageResolution).flatMap { StorageResolution(rawValue: $0) }
            ?? .standard
    }

    var canEditSettings: Bool {
        recorder.map { $0.session.state == .finished } ?? true
    }

    var canStartRecording: Bool {
        store != nil && selectedDisplayUUID != nil
    }

    func refreshScreenCapturePermission() {
        isScreenCaptureAllowed = ScreenCapturePermission.isGranted
    }

    func requestScreenCaptureAccess() {
        if defaults.bool(forKey: PreferenceKey.hasRequestedScreenCapture) {
            ScreenCapturePermission.openSystemSettings()
        } else {
            defaults.set(true, forKey: PreferenceKey.hasRequestedScreenCapture)
            ScreenCapturePermission.request()
        }
        refreshScreenCapturePermission()
    }

    func loadDisplays() async {
        do {
            displays = try await DisplayCatalog.capturableDisplays()
            if !displays.contains(where: { $0.uuid == selectedDisplayUUID }) {
                selectedDisplayUUID = displays.first?.uuid
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startNewTimelapse() {
        guard let store, let selectedDisplayUUID else { return }
        let settings = CaptureSettings(
            captureIntervalSeconds: captureIntervalSeconds,
            displayUUID: selectedDisplayUUID,
            storageResolution: storageResolution
        )
        let recorder = TimelapseRecorder(session: TimelapseSession(state: .paused, settings: settings), store: store)
        self.recorder = recorder
        changeState { try recorder.record() }
    }

    func pause() {
        changeState { try await self.recorder?.pause() }
    }

    func resume() {
        changeState { try self.recorder?.record() }
    }

    func stop() {
        changeState { try await self.recorder?.stop() }
    }

    private func changeState(_ change: @escaping @MainActor () async throws -> Void) {
        isChangingState = true
        Task {
            defer { isChangingState = false }
            do {
                try await change()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private enum PreferenceKey {
    static let displayUUID = "capture.displayUUID"
    static let captureIntervalSeconds = "capture.intervalSeconds"
    static let storageResolution = "capture.storageResolution"
    static let hasRequestedScreenCapture = "permissions.hasRequestedScreenCapture"
}
