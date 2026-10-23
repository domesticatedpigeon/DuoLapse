import Testing

@testable import DuoLapseCore

struct FrameSamplerTests {
    @Test func returnsEveryFrameWhenTargetCoversAll() {
        #expect(FrameSampler.indices(selecting: 10, from: 4) == [0, 1, 2, 3])
    }

    @Test func spreadsSamplesEvenlyIncludingFirstAndLast() {
        #expect(FrameSampler.indices(selecting: 5, from: 9) == [0, 2, 4, 6, 8])
    }

    @Test func samplesAreStrictlyIncreasing() {
        let indices = FrameSampler.indices(selecting: 900, from: 28_800)
        #expect(indices.count == 900)
        #expect(zip(indices, indices.dropFirst()).allSatisfy { $0 < $1 })
        #expect(indices.last == 28_799)
    }

    @Test(arguments: [(0, 10), (5, 0)])
    func emptyInputsGiveNoFrames(target: Int, available: Int) {
        #expect(FrameSampler.indices(selecting: target, from: available).isEmpty)
    }

    @Test func singleTargetPicksFirstFrame() {
        #expect(FrameSampler.indices(selecting: 1, from: 10) == [0])
    }
}
