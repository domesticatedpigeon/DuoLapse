import Foundation
import Testing

@testable import DuoLapseCore

struct FrameTimelineTests {
    let start = Date(timeIntervalSince1970: 1_761_150_000)

    func at(_ seconds: Double) -> Date {
        start.addingTimeInterval(seconds)
    }

    @Test func pairsFramesCapturedOnTheSameTick() {
        let frames = FrameTimeline.frames(
            screen: [at(0), at(5)],
            camera: [at(0.001), at(5.002)],
            tolerance: 2.5
        )
        #expect(frames.map(\.screenFrameIndex) == [0, 1])
        #expect(frames.map(\.cameraFrameIndex) == [0, 1])
        #expect(frames.map(\.capturedAt) == [at(0), at(5)])
    }

    @Test func reusesLatestCameraFrameWhenCameraMissedATick() {
        let frames = FrameTimeline.frames(screen: [at(0), at(5), at(10)], camera: [at(0), at(10)], tolerance: 2.5)
        #expect(frames.map(\.cameraFrameIndex) == [0, 0, 1])
    }

    @Test func leavesSourceEmptyUntilItsFirstFrame() {
        let frames = FrameTimeline.frames(screen: [at(0), at(5)], camera: [at(5)], tolerance: 2.5)
        #expect(frames.map(\.cameraFrameIndex) == [nil, 0])
    }

    @Test func screenOnlyTimelineHasNoCameraFrames() {
        let frames = FrameTimeline.frames(screen: [at(0), at(1), at(2)], camera: [], tolerance: 0.5)
        #expect(frames.count == 3)
        #expect(frames.allSatisfy { $0.cameraFrameIndex == nil })
    }

    @Test func cameraOnlyTimelineHasNoScreenFrames() {
        let frames = FrameTimeline.frames(screen: [], camera: [at(0), at(1)], tolerance: 0.5)
        #expect(frames.map(\.cameraFrameIndex) == [0, 1])
        #expect(frames.allSatisfy { $0.screenFrameIndex == nil })
    }
}
