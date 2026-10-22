import Testing

@testable import DuoLapseCore

struct RecordingPolicyTests {
    @Test func pausesRecordingAfterAMinuteIdle() {
        #expect(
            RecordingPolicy.idleAction(for: .recording, idleSeconds: 60, isSmartPauseEnabled: true) == .pauseForIdle)
    }

    @Test func keepsRecordingBeforeAMinuteIdle() {
        #expect(RecordingPolicy.idleAction(for: .recording, idleSeconds: 59, isSmartPauseEnabled: true) == .none)
    }

    @Test func neverPausesWhenSmartPauseIsOff() {
        #expect(RecordingPolicy.idleAction(for: .recording, idleSeconds: 3600, isSmartPauseEnabled: false) == .none)
    }

    @Test(arguments: [true, false])
    func resumesIdlePausedRecordingOnInput(isSmartPauseEnabled: Bool) {
        let action = RecordingPolicy.idleAction(
            for: .idlePaused,
            idleSeconds: 0.5,
            isSmartPauseEnabled: isSmartPauseEnabled
        )
        #expect(action == .resumeFromIdle)
    }

    @Test func staysIdlePausedWithoutInput() {
        #expect(RecordingPolicy.idleAction(for: .idlePaused, idleSeconds: 120, isSmartPauseEnabled: true) == .none)
    }

    @Test(arguments: [TimelapseState.paused, .finished])
    func neverResumesManuallyPausedOrClosedTimelapses(state: TimelapseState) {
        #expect(RecordingPolicy.idleAction(for: state, idleSeconds: 0, isSmartPauseEnabled: true) == .none)
    }

    @Test func preventsSleepWhileRecordingOrIdlePaused() {
        #expect(RecordingPolicy.shouldPreventSleep(states: [.paused, .recording], isKeepAwakeEnabled: true))
        #expect(RecordingPolicy.shouldPreventSleep(states: [.idlePaused], isKeepAwakeEnabled: true))
    }

    @Test func allowsSleepWhenNothingIsRecording() {
        #expect(!RecordingPolicy.shouldPreventSleep(states: [.paused, .finished], isKeepAwakeEnabled: true))
    }

    @Test func allowsSleepWhenKeepAwakeIsOff() {
        #expect(!RecordingPolicy.shouldPreventSleep(states: [.recording], isKeepAwakeEnabled: false))
    }

    @Test(arguments: [(Int64(1_999_999_999), false), (2_000_000_000, true), (50_000_000_000, true)])
    func requiresTwoGigabytesFree(availableBytes: Int64, hasEnough: Bool) {
        #expect(RecordingPolicy.hasEnoughFreeSpace(availableBytes: availableBytes) == hasEnough)
    }

    @Test(arguments: [(29.9, false), (30.0, true)])
    func pausesAfterThirtySecondsOfScreenFailures(seconds: Double, shouldPause: Bool) {
        #expect(RecordingPolicy.shouldPauseForScreenFailures(failingForSeconds: seconds) == shouldPause)
    }
}
