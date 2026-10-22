import CoreMedia
import DuoLapseCore
import Foundation
import Observation

@Observable
public final class TimelapseRecorder {
    public private(set) var session: TimelapseSession
    public private(set) var capturedFrameCount = 0
    public private(set) var bytesOnDisk: Int
    public private(set) var lastCaptureError: String?

    @ObservationIgnored private let store: SessionStore
    @ObservationIgnored private var captureTask: Task<Void, Never>?
    @ObservationIgnored private var segmentWriter: SegmentWriter?

    public init(session: TimelapseSession, store: SessionStore) {
        self.session = session
        self.store = store
        self.bytesOnDisk = store.diskUsage(of: session.id)
    }

    public func record() throws {
        guard captureTask == nil, session.state != .finished else { return }
        try updateState(.recording)
        let scheduler = CaptureScheduler(interval: session.settings.captureInterval, clock: ContinuousClock())
        captureTask = Task {
            await scheduler.run { [weak self] in
                await self?.captureFrame()
            }
        }
    }

    public func pause() async throws {
        guard session.state == .recording else { return }
        await stopCapturing()
        try updateState(.paused)
    }

    public func stop() async throws {
        guard session.state != .finished else { return }
        await stopCapturing()
        try updateState(.finished)
    }

    private func captureFrame() async {
        do {
            let capturedAt = Date.now
            let sampleBuffer = try await ScreenFrameSource.captureFrame(
                displayUUID: session.settings.displayUUID,
                resolution: session.settings.storageResolution
            )
            guard let pixelBuffer = sampleBuffer.imageBuffer else { throw ScreenCaptureError.frameMissingImage }
            let frameSize = PixelSize(
                width: CVPixelBufferGetWidth(pixelBuffer),
                height: CVPixelBufferGetHeight(pixelBuffer)
            )
            let writer = try await writerForFrame(ofSize: frameSize, capturedAt: capturedAt)
            if writer.append(pixelBuffer, capturedAt: capturedAt) {
                capturedFrameCount += 1
            }
            lastCaptureError = nil
        } catch {
            lastCaptureError = error.localizedDescription
        }
        bytesOnDisk = store.diskUsage(of: session.id)
    }

    private func writerForFrame(ofSize frameSize: PixelSize, capturedAt date: Date) async throws -> SegmentWriter {
        if let segmentWriter, segmentWriter.accepts(frameOfSize: frameSize, capturedAt: date) {
            return segmentWriter
        }
        await finishSegment()
        let url = store.screenSegmentsDirectory(for: session.id).appending(path: SegmentFile.name(startingAt: date))
        let writer = try SegmentWriter(
            url: url,
            startDate: date,
            size: frameSize,
            captureIntervalSeconds: session.settings.captureIntervalSeconds
        )
        segmentWriter = writer
        return writer
    }

    private func stopCapturing() async {
        captureTask?.cancel()
        await captureTask?.value
        captureTask = nil
        await finishSegment()
        bytesOnDisk = store.diskUsage(of: session.id)
    }

    private func finishSegment() async {
        guard let writer = segmentWriter else { return }
        segmentWriter = nil
        await writer.finish()
    }

    private func updateState(_ state: TimelapseState) throws {
        session.state = state
        session.updatedAt = .now
        try store.save(session)
    }
}
