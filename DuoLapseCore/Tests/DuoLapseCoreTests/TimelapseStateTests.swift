import Foundation
import Testing

@testable import DuoLapseCore

struct TimelapseStateTests {
    @Test(arguments: [
        (TimelapseState.recording, "recording"),
        (.paused, "paused"),
        (.idlePaused, "idlePaused"),
        (.finished, "finished"),
    ])
    func persistedRawValueIsStable(state: TimelapseState, rawValue: String) {
        #expect(state.rawValue == rawValue)
    }

    @Test(arguments: TimelapseState.allCases)
    func roundTripsThroughJSON(state: TimelapseState) throws {
        let data = try JSONEncoder().encode(state)
        #expect(try JSONDecoder().decode(TimelapseState.self, from: data) == state)
    }

    @Test func onlyRecordingIsCapturing() {
        #expect(TimelapseState.allCases.filter(\.isCapturing) == [.recording])
    }

    @Test func onlyPausedStatesCanResume() {
        #expect(TimelapseState.allCases.filter(\.canResume) == [.paused, .idlePaused])
    }
}
