@preconcurrency import AVFoundation
import CoreImage
import CoreMedia
import CoreVideo
import DuoLapseCore
import Foundation

public struct VideoExporter: Sendable {
    private static let progressReportInterval = 15

    public init() {}

    @concurrent
    public func prepareSource(for session: TimelapseSession, store: SessionStore) async throws -> ExportSource {
        let screenSegments = store.segments(of: session.id, source: .screen)
        let cameraSegments = store.segments(of: session.id, source: .camera)
        let screenDates = try await SegmentFrameIndex.captureDates(in: screenSegments)
        let cameraDates = try await SegmentFrameIndex.captureDates(in: cameraSegments)
        let screenSize = try await SegmentFrameIndex.frameSize(of: screenDates.isEmpty ? [] : screenSegments)
        let cameraSize = try await SegmentFrameIndex.frameSize(of: cameraDates.isEmpty ? [] : cameraSegments)
        return ExportSource(
            session: session,
            frames: FrameTimeline.frames(
                screen: screenDates,
                camera: cameraDates,
                tolerance: Double(session.settings.captureIntervalSeconds) / 2
            ),
            screenSize: screenSize,
            cameraSize: cameraSize,
            screenSegments: screenSegments,
            cameraSegments: cameraSegments
        )
    }

    @concurrent
    public func previewImage(of source: ExportSource, settings: ExportSettings) async throws -> sending CGImage? {
        let representativeFrame =
            source.frames.first { $0.screenFrameIndex != nil && $0.cameraFrameIndex != nil } ?? source.frames.first
        guard let frame = representativeFrame else { return nil }
        let compositor = FrameCompositor(plan: Self.layoutPlan(for: source, settings: settings))
        let screen = try await SourceFrameDecoder(segments: source.screenSegments).frame(at: frame.screenFrameIndex)
        let camera = try await SourceFrameDecoder(segments: source.cameraSegments).frame(at: frame.cameraFrameIndex)
        let image = compositor.composite(
            screen: screen,
            camera: camera,
            timestamp: settings.includesTimestamp ? Self.timestampText(for: frame.capturedAt) : nil
        )
        return compositor.makeCGImage(image)
    }

    @concurrent
    public func export(
        _ source: ExportSource,
        settings: ExportSettings,
        to url: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        let selection = FrameSampler.indices(
            selecting: settings.duration.frameCount(availableFrames: source.frames.count),
            from: source.frames.count
        )
        guard !selection.isEmpty else { throw ExportError.noFrames }
        let plan = Self.layoutPlan(for: source, settings: settings)
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: Self.outputSettings(canvas: plan.canvasSize, codec: settings.codec)
        )
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: plan.canvasSize.width,
                kCVPixelBufferHeightKey as String: plan.canvasSize.height,
                kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any](),
            ]
        )
        guard writer.canAdd(input) else { throw ExportError.cannotWriteVideo }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? ExportError.cannotWriteVideo }
        writer.startSession(atSourceTime: .zero)

        do {
            let compositor = FrameCompositor(plan: plan)
            let screenDecoder = SourceFrameDecoder(segments: source.screenSegments)
            let cameraDecoder = SourceFrameDecoder(segments: source.cameraSegments)
            for (outputIndex, frameIndex) in selection.enumerated() {
                try Task.checkCancellation()
                let frame = source.frames[frameIndex]
                let image = compositor.composite(
                    screen: try await screenDecoder.frame(at: frame.screenFrameIndex),
                    camera: try await cameraDecoder.frame(at: frame.cameraFrameIndex),
                    timestamp: settings.includesTimestamp ? Self.timestampText(for: frame.capturedAt) : nil
                )
                let pixelBuffer = try Self.makePixelBuffer(from: adaptor)
                compositor.render(image, to: pixelBuffer)
                while !input.isReadyForMoreMediaData {
                    try await Task.sleep(for: .milliseconds(2))
                }
                let presentationTime = CMTime(
                    value: CMTimeValue(outputIndex),
                    timescale: CMTimeScale(ExportDuration.framesPerSecond)
                )
                guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else {
                    throw writer.error ?? ExportError.cannotWriteVideo
                }
                let completedCount = outputIndex + 1
                if completedCount % Self.progressReportInterval == 0 || completedCount == selection.count {
                    progress(Double(completedCount) / Double(selection.count))
                }
            }
            input.markAsFinished()
            await withCheckedContinuation { continuation in
                writer.finishWriting { continuation.resume() }
            }
            guard writer.status == .completed else { throw writer.error ?? ExportError.cannotWriteVideo }
        } catch {
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    public static func timestampText(for date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    private static func layoutPlan(for source: ExportSource, settings: ExportSettings) -> LayoutPlan {
        LayoutEngine.plan(
            layout: settings.layout,
            screenSize: source.screenSize,
            cameraSize: source.cameraSize,
            longEdge: source.session.settings.storageResolution.screenLongEdge
        )
    }

    private static func makePixelBuffer(from adaptor: AVAssetWriterInputPixelBufferAdaptor) throws -> CVPixelBuffer {
        guard let pool = adaptor.pixelBufferPool else { throw ExportError.cannotWriteVideo }
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
        guard let pixelBuffer else { throw ExportError.cannotWriteVideo }
        return pixelBuffer
    }

    private static func outputSettings(canvas: PixelSize, codec: ExportCodec) -> [String: Any] {
        let pixelsPerSecond = Double(canvas.width * canvas.height * ExportDuration.framesPerSecond)
        let bitsPerPixel = codec == .hevc ? 0.12 : 0.2
        return [
            AVVideoCodecKey: codec == .hevc ? AVVideoCodecType.hevc : AVVideoCodecType.h264,
            AVVideoWidthKey: canvas.width,
            AVVideoHeightKey: canvas.height,
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
            ],
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: Int(pixelsPerSecond * bitsPerPixel),
                AVVideoExpectedSourceFrameRateKey: ExportDuration.framesPerSecond,
                AVVideoMaxKeyFrameIntervalKey: ExportDuration.framesPerSecond * 2,
            ],
        ]
    }
}
