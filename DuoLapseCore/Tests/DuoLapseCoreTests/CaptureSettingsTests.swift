import Testing

@testable import DuoLapseCore

struct CaptureSettingsTests {
    @Test func clampsIntervalToAtLeastOneSecond() {
        let settings = CaptureSettings(captureIntervalSeconds: 0, displayUUID: "DISPLAY", storageResolution: .standard)
        #expect(settings.captureInterval == .seconds(1))
    }

    @Test func exposesIntervalAsDuration() {
        let settings = CaptureSettings(captureIntervalSeconds: 5, displayUUID: "DISPLAY", storageResolution: .standard)
        #expect(settings.captureInterval == .seconds(5))
    }
}
