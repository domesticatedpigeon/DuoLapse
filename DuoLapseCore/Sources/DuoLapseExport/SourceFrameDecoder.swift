@preconcurrency import AVFoundation
import CoreMedia
import CoreVideo
import Foundation

final class SourceFrameDecoder {
    private let segments: [URL]
    private var nextSegmentIndex = 0
    private var output: AVAssetReaderTrackOutput?
    private var reader: AVAssetReader?
    private var currentFrame: CVPixelBuffer?
    private var currentFrameIndex = -1

    init(segments: [URL]) {
        self.segments = segments
    }

    func frame(at index: Int?) async throws -> CVPixelBuffer? {
        guard let index else { return nil }
        while currentFrameIndex < index {
            guard let nextFrame = try await nextDecodedFrame() else { throw ExportError.missingFrame }
            currentFrame = nextFrame
            currentFrameIndex += 1
        }
        return currentFrame
    }

    private func nextDecodedFrame() async throws -> CVPixelBuffer? {
        while true {
            if let output {
                if let sampleBuffer = output.copyNextSampleBuffer() {
                    if let imageBuffer = sampleBuffer.imageBuffer {
                        return imageBuffer
                    }
                    continue
                }
                self.output = nil
                reader = nil
            }
            guard nextSegmentIndex < segments.count else { return nil }
            try await openSegment(segments[nextSegmentIndex])
            nextSegmentIndex += 1
        }
    }

    private func openSegment(_ url: URL) async throws {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { return }
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        output.alwaysCopiesSampleData = false
        reader.add(output)
        guard reader.startReading() else { return }
        self.reader = reader
        self.output = output
    }
}
