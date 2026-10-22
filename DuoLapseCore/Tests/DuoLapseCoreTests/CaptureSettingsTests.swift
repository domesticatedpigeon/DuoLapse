import Foundation
import Testing

@testable import DuoLapseCore

struct CaptureSettingsTests {
    @Test func clampsIntervalToAtLeastOneSecond() {
        let settings = CaptureSettings(
            captureIntervalSeconds: 0,
            storageResolution: .standard,
            displayUUID: "DISPLAY",
            cameraID: nil
        )
        #expect(settings.captureInterval == .seconds(1))
    }

    static let deviceSelections: [(String?, String?, [CaptureSource])] = [
        ("DISPLAY", nil, [.screen]),
        (nil, "CAMERA", [.camera]),
        ("DISPLAY", "CAMERA", [.screen, .camera]),
        (nil, nil, []),
    ]

    @Test(arguments: deviceSelections)
    func sourcesFollowSelectedDevices(displayUUID: String?, cameraID: String?, expected: [CaptureSource]) {
        let settings = CaptureSettings(
            captureIntervalSeconds: 5,
            storageResolution: .standard,
            displayUUID: displayUUID,
            cameraID: cameraID
        )
        #expect(settings.sources == expected)
    }

    @Test func decodesScreenOnlySettingsSavedBeforeCameraSupport() throws {
        let json = #"{"captureIntervalSeconds":5,"displayUUID":"DISPLAY","storageResolution":"standard"}"#
        let settings = try JSONDecoder().decode(CaptureSettings.self, from: Data(json.utf8))
        #expect(settings.displayUUID == "DISPLAY")
        #expect(settings.cameraID == nil)
    }
}
