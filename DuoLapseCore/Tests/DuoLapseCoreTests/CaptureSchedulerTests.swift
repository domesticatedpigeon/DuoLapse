import Testing

@testable import DuoLapseCore

struct CaptureSchedulerTests {
    typealias Scheduler = CaptureScheduler<ContinuousClock>

    let start = ContinuousClock.now

    @Test func waitsOneIntervalAfterOnTimeCapture() {
        let next = Scheduler.nextDeadline(after: start, now: start + .milliseconds(300), interval: .seconds(1))
        #expect(next == start + .seconds(1))
    }

    @Test func skipsTicksMissedBySlowCapture() {
        let next = Scheduler.nextDeadline(after: start, now: start + .milliseconds(2500), interval: .seconds(1))
        #expect(next == start + .seconds(3))
    }

    @Test func keepsDeadlineThatFallsExactlyOnNow() {
        let next = Scheduler.nextDeadline(after: start, now: start + .seconds(1), interval: .seconds(1))
        #expect(next == start + .seconds(1))
    }

    @Test func runsTicksUntilCancelled() async {
        let counter = TickCounter()
        let scheduler = Scheduler(interval: .milliseconds(5), clock: ContinuousClock())
        let task = Task {
            await scheduler.run {
                if await counter.increment() >= 3 {
                    withUnsafeCurrentTask { $0?.cancel() }
                }
            }
        }
        await task.value
        #expect(await counter.count == 3)
    }
}

private actor TickCounter {
    private(set) var count = 0

    func increment() -> Int {
        count += 1
        return count
    }
}
