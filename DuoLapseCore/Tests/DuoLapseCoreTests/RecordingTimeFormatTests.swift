import Testing

@testable import DuoLapseCore

struct RecordingTimeFormatTests {
    @Test(arguments: [
        (0.0, "0:00"),
        (59.9, "0:59"),
        (61, "1:01"),
        (219, "3:39"),
        (3599, "59:59"),
        (3600, "1:00:00"),
        (3723, "1:02:03"),
        (-5, "0:00"),
    ])
    func formatsLikeTheClockTimer(seconds: Double, expected: String) {
        #expect(RecordingTimeFormat.compact(seconds: seconds) == expected)
    }
}
