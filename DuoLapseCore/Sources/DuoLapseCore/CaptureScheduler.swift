public struct CaptureScheduler<C: Clock>: Sendable where C.Duration == Duration {
    public let interval: Duration
    public let clock: C

    public init(interval: Duration, clock: C) {
        self.interval = interval
        self.clock = clock
    }

    public func run(_ tick: @Sendable () async -> Void) async {
        var deadline = clock.now
        while !Task.isCancelled {
            await tick()
            deadline = Self.nextDeadline(after: deadline, now: clock.now, interval: interval)
            do {
                try await clock.sleep(until: deadline, tolerance: interval / 20)
            } catch {
                return
            }
        }
    }

    public static func nextDeadline(after previous: C.Instant, now: C.Instant, interval: Duration) -> C.Instant {
        var next = previous.advanced(by: interval)
        while next < now {
            next = next.advanced(by: interval)
        }
        return next
    }
}
