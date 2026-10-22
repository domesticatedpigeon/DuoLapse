import Testing

@testable import DuoLapseCore

struct ExportDurationTests {
    @Test func presetsAreThirtySecondsOneMinuteThreeMinutesAndFullLength() {
        #expect(ExportDuration.presets == [.seconds(30), .seconds(60), .seconds(180), .fullLength])
    }

    @Test func frameCountIsSecondsAtThirtyFramesPerSecond() {
        #expect(ExportDuration.seconds(30).frameCount(availableFrames: 10_000) == 900)
    }

    @Test func frameCountNeverExceedsAvailableFrames() {
        #expect(ExportDuration.seconds(60).frameCount(availableFrames: 500) == 500)
    }

    @Test func fullLengthUsesEveryFrame() {
        #expect(ExportDuration.fullLength.frameCount(availableFrames: 1234) == 1234)
    }

    @Test(arguments: [(899, false), (900, true), (5000, true)])
    func thirtySecondsFitsOnlyWithEnoughFrames(availableFrames: Int, fits: Bool) {
        #expect(ExportDuration.seconds(30).fits(availableFrames: availableFrames) == fits)
    }

    @Test func customDurationIsNotAPreset() {
        #expect(!ExportDuration.seconds(45).isPreset)
        #expect(ExportDuration.seconds(60).isPreset)
    }

    @Test func fullLengthSecondsDividesByFrameRate() {
        #expect(ExportDuration.fullLengthSeconds(availableFrames: 450) == 15)
    }
}
