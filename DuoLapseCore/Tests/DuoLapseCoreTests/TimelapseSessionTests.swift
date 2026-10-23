import Foundation
import Testing

@testable import DuoLapseCore

struct TimelapseSessionTests {
    let settings = CaptureSettings(
        captureIntervalSeconds: 5,
        storageResolution: .standard,
        displayUUID: "DISPLAY",
        cameraID: nil
    )

    @Test func decodesSessionSavedBeforeStatisticsWereTracked() throws {
        let json = """
            {
              "id": "6F9619FF-8B86-D011-B42D-00C04FC964FF",
              "createdAt": "2026-10-22T15:00:00Z",
              "updatedAt": "2026-10-22T15:10:00Z",
              "state": "paused",
              "settings": {"captureIntervalSeconds": 5, "storageResolution": "standard", "displayUUID": "DISPLAY"}
            }
            """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let session = try decoder.decode(TimelapseSession.self, from: Data(json.utf8))
        #expect(session.recordedSeconds == 0)
        #expect(session.capturedFrameCount == 0)
        #expect(session.state == .paused)
        #expect(session.name == nil)
    }

    @Test func renamingTrimsWhitespace() {
        var session = TimelapseSession(state: .paused, settings: settings)
        session.rename(to: "  Sketching a logo \n")
        #expect(session.name == "Sketching a logo")
    }

    @Test func renamingToBlankClearsTheName() {
        var session = TimelapseSession(state: .paused, settings: settings, name: "Logo")
        session.rename(to: "   ")
        #expect(session.name == nil)
    }

    @Test func nameRoundTripsThroughSessionFile() throws {
        let session = TimelapseSession(state: .finished, settings: settings, name: "Logo")
        let decoded = try JSONDecoder().decode(TimelapseSession.self, from: JSONEncoder().encode(session))
        #expect(decoded.name == "Logo")
    }

    @Test func onlyFinishedSessionsAreClosed() {
        let openStates = TimelapseState.allCases.filter { TimelapseSession(state: $0, settings: settings).isOpen }
        #expect(openStates == [.recording, .paused, .idlePaused])
    }
}
