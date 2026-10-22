import CoreMedia
import CoreVideo
import DuoLapseCore
import Foundation
import Observation

@Observable
public final class TimelapseRecorder {
    public private(set) var session: TimelapseSession
    public private(set) var capturedFrameCounts: [CaptureSource: Int] = [:]
    public private(set) var bytesOnDisk: Int
    public private(set) var lastCaptureError: String?

    @ObservationIgnored private let store: SessionStore
    @ObservationIgnored private var captureTask: Task<Void, Never>?
    @ObservationIgnored private var cameraSource: CameraFrameSource?
    @ObservationIgnored private var segmentWriters: [CaptureSource: SegmentWriter] = [:]
    @ObservationIgnored private var capturingSince: ContinuousClock.Instant?

    private static let checkpointFrameInterval = 30

    public init(session: TimelapseSession, store: SessionStore) {
        self.session = session
        self.store = store
        self.bytesOnDisk = store.diskUsage(of: session.id)
    }

    public var recordedDuration: Duration {
        .seconds(session.recordedSeconds) + (capturingSince.map { ContinuousClock.now - $0 } ?? .zero)
    }

    public var isCapturing: Bool {
        session.state == .recording
    }

    public func record() async throws {
        guard captureTask == nil, session.state != .finished else { return }
        if let cameraID = session.settings.cameraID {
            let camera = CameraFrameSource(deviceID: cameraID)
            try await camera.start()
            cameraSource = camera
        }
        try updateState(.recording)
        capturingSince = .now
        let scheduler = CaptureScheduler(interval: session.settings.captureInterval, clock: ContinuousClock())
        captureTask = Task {
            await scheduler.run { [weak self] in
                await self?.captureFrames()
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

    private func captureFrames() async {
        let capturedAt = Date.now
        var errorDescriptions: [String] = []
        var appendedSources = 0
        if let displayUUID = session.settings.displayUUID {
            do {
                let sampleBuffer = try await ScreenFrameSource.captureFrame(
                    displayUUID: displayUUID,
                    resolution: session.settings.storageResolution
                )
                guard let pixelBuffer = sampleBuffer.imageBuffer else { throw ScreenCaptureError.frameMissingImage }
                if try await append(pixelBuffer, from: .screen, capturedAt: capturedAt) {
                    appendedSources += 1
                }
            } catch {
                errorDescriptions.append(error.localizedDescription)
            }
        }
        if let cameraSource {
            do {
                if try await append(try cameraSource.currentFrame(), from: .camera, capturedAt: capturedAt) {
                    appendedSources += 1
                }
            } catch {
                errorDescriptions.append(error.localizedDescription)
            }
        }
        if appendedSources > 0 {
            session.capturedFrameCount += 1
            if session.capturedFrameCount.isMultiple(of: Self.checkpointFrameInterval) {
                try? saveCheckpoint()
            }
        }
        lastCaptureError = errorDescriptions.isEmpty ? nil : errorDescriptions.joined(separator: "\n")
        bytesOnDisk = store.diskUsage(of: session.id)
    }

    private func append(_ pixelBuffer: CVPixelBuffer, from source: CaptureSource, capturedAt date: Date) async throws
        -> Bool
    {
        let frameSize = PixelSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        let writer = try await segmentWriter(for: source, frameSize: frameSize, capturedAt: date)
        guard writer.append(pixelBuffer, capturedAt: date) else { return false }
        capturedFrameCounts[source, default: 0] += 1
        return true
    }

    private func segmentWriter(for source: CaptureSource, frameSize: PixelSize, capturedAt date: Date) async throws
        -> SegmentWriter
    {
        if let writer = segmentWriters[source], writer.accepts(frameOfSize: frameSize, capturedAt: date) {
            return writer
        }
        await finishSegment(of: source)
        let url = store.segmentsDirectory(for: session.id, source: source)
            .appending(path: SegmentFile.name(startingAt: date))
        let writer = try SegmentWriter(
            url: url,
            startDate: date,
            size: frameSize,
            captureIntervalSeconds: session.settings.captureIntervalSeconds
        )
        segmentWriters[source] = writer
        return writer
    }

    private func stopCapturing() async {
        captureTask?.cancel()
        await captureTask?.value
        captureTask = nil
        foldCapturingTimeIntoSession()
        await cameraSource?.stop()
        cameraSource = nil
        for source in CaptureSource.allCases {
            await finishSegment(of: source)
        }
        bytesOnDisk = store.diskUsage(of: session.id)
    }

    private func finishSegment(of source: CaptureSource) async {
        guard let writer = segmentWriters.removeValue(forKey: source) else { return }
        await writer.finish()
    }

    private func saveCheckpoint() throws {
        foldCapturingTimeIntoSession()
        capturingSince = .now
        session.updatedAt = .now
        try store.save(session)
    }

    private func foldCapturingTimeIntoSession() {
        guard let capturingSince else { return }
        let elapsed = ContinuousClock.now - capturingSince
        session.recordedSeconds +=
            Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        self.capturingSince = nil
    }

    private func updateState(_ state: TimelapseState) throws {
        session.state = state
        session.updatedAt = .now
        try store.save(session)
    }
}
