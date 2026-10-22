@preconcurrency import AVFoundation
import CoreMedia
import CoreVideo
import DuoLapseCore
import Foundation

final class SegmentWriter {
    static let maximumDuration: TimeInterval = 600

    let url: URL
    let startDate: Date
    let size: PixelSize
    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private var lastPresentationTime = CMTime.negativeInfinity
    private var appendedFrameCount = 0

    init(url: URL, startDate: Date, size: PixelSize, captureIntervalSeconds: Int) throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        writer.movieFragmentInterval = CMTime(seconds: 10, preferredTimescale: 600)
        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: Self.outputSettings(
                size: size,
                captureIntervalSeconds: captureIntervalSeconds,
                writer: writer
            )
        )
        input.expectsMediaDataInRealTime = true
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        guard writer.canAdd(input) else { throw SegmentWriterError.cannotAddVideoInput }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? SegmentWriterError.cannotStartWriting }
        writer.startSession(atSourceTime: .zero)

        self.url = url
        self.startDate = startDate
        self.size = size
        self.writer = writer
        self.input = input
        self.adaptor = adaptor
    }

    func accepts(frameOfSize frameSize: PixelSize, capturedAt date: Date) -> Bool {
        frameSize == size && date.timeIntervalSince(startDate) < Self.maximumDuration
    }

    func append(_ pixelBuffer: CVPixelBuffer, capturedAt date: Date) -> Bool {
        let presentationTime = CMTime(seconds: max(0, date.timeIntervalSince(startDate)), preferredTimescale: 1000)
        guard writer.status == .writing, input.isReadyForMoreMediaData, presentationTime > lastPresentationTime else {
            return false
        }
        guard adaptor.append(pixelBuffer, withPresentationTime: presentationTime) else { return false }
        lastPresentationTime = presentationTime
        appendedFrameCount += 1
        return true
    }

    func finish() async {
        guard appendedFrameCount > 0 else {
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: url)
            return
        }
        input.markAsFinished()
        await withCheckedContinuation { continuation in
            writer.finishWriting { continuation.resume() }
        }
    }

    private static func outputSettings(
        size: PixelSize,
        captureIntervalSeconds: Int,
        writer: AVAssetWriter
    ) -> [String: Any] {
        let dimensions: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height,
        ]
        let sharedCompression: [String: Any] = [
            AVVideoMaxKeyFrameIntervalKey: 120,
            AVVideoAllowFrameReorderingKey: false,
        ]
        let constantQuality = dimensions.merging([
            AVVideoCompressionPropertiesKey: sharedCompression.merging([AVVideoQualityKey: 0.5]) { $1 }
        ]) { $1 }
        if writer.canApply(outputSettings: constantQuality, forMediaType: .video) {
            return constantQuality
        }
        let targetBitsPerFrame = 40_000 * 8
        return dimensions.merging([
            AVVideoCompressionPropertiesKey: sharedCompression.merging([
                AVVideoAverageBitRateKey: targetBitsPerFrame / max(1, captureIntervalSeconds)
            ]) { $1 }
        ]) { $1 }
    }
}

nonisolated enum SegmentWriterError: LocalizedError {
    case cannotAddVideoInput
    case cannotStartWriting

    var errorDescription: String? {
        switch self {
        case .cannotAddVideoInput: "DuoLapse couldn’t set up the video encoder."
        case .cannotStartWriting: "DuoLapse couldn’t start writing the recording to disk."
        }
    }
}
