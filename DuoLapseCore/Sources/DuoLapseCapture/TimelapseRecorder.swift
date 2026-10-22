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

    public init(session: TimelapseSession, store: SessionStore) {
        self.session = session
        self.store = store
        self.bytesOnDisk = store.diskUsage(of: session.id)
    }

    public func record() async throws {
        guard captureTask == nil, session.state != .finished else { return }
        if let cameraID = session.settings.cameraID {
            let camera = CameraFrameSource(deviceID: cameraID)
            try await camera.start()
            cameraSource = camera
        }
        try updateState(.recording)
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
        if let displayUUID = session.settings.displayUUID {
            do {
                let sampleBuffer = try await ScreenFrameSource.captureFrame(
                    displayUUID: displayUUID,
                    resolution: session.settings.storageResolution
                )
                guard let pixelBuffer = sampleBuffer.imageBuffer else { throw ScreenCaptureError.frameMissingImage }
                try await append(pixelBuffer, from: .screen, capturedAt: capturedAt)
            } catch {
                errorDescriptions.append(error.localizedDescription)
            }
        }
        if let cameraSource {
            do {
                try await append(try cameraSource.currentFrame(), from: .camera, capturedAt: capturedAt)
            } catch {
                errorDescriptions.append(error.localizedDescription)
            }
        }
        lastCaptureError = errorDescriptions.isEmpty ? nil : errorDescriptions.joined(separator: "\n")
        bytesOnDisk = store.diskUsage(of: session.id)
    }

    private func append(_ pixelBuffer: CVPixelBuffer, from source: CaptureSource, capturedAt date: Date) async throws {
        let frameSize = PixelSize(
            width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let writer = try await segmentWriter(for: source, frameSize: frameSize, capturedAt: date)
        if writer.append(pixelBuffer, capturedAt: date) {
            capturedFrameCounts[source, default: 0] += 1
        }
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

    private func updateState(_ state: TimelapseState) throws {
        session.state = state
        session.updatedAt = .now
        try store.save(session)
    }
}
