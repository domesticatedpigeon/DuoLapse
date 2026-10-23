import Foundation
import Testing

@testable import DuoLapseCore

struct SegmentFileTests {
    @Test func namesSegmentByStartInMilliseconds() {
        let date = Date(timeIntervalSince1970: 1_761_150_000.123)
        #expect(SegmentFile.name(startingAt: date) == "1761150000123.mp4")
    }

    @Test func parsesStartDateBackFromName() throws {
        let date = try #require(SegmentFile.startDate(ofSegmentNamed: "1761150000123.mp4"))
        #expect(abs(date.timeIntervalSince1970 - 1_761_150_000.123) < 0.001)
    }

    @Test(arguments: ["session.json", "notes.mp4", "1761150000123.mov", ".mp4"])
    func rejectsNamesThatAreNotSegments(name: String) {
        #expect(SegmentFile.startDate(ofSegmentNamed: name) == nil)
    }
}
