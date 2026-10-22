import AVFoundation
import CoreVideo
import DuoLapseCore
import Foundation
import Testing

@testable import DuoLapseCapture

@MainActor
struct SegmentWriterTests {
    let size = PixelSize(width: 320, height: 180)

    @Test func writesEveryAppendedFrameToAReadableSegment() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: url) }
        let start = Date.now
        let writer = try SegmentWriter(url: url, startDate: start, size: size, captureIntervalSeconds: 1)

        for second in 0..<3 {
            let appended = writer.append(try makePixelBuffer(), capturedAt: start.addingTimeInterval(Double(second)))
            #expect(appended)
            try await Task.sleep(for: .milliseconds(50))
        }
        await writer.finish()

        #expect(try await sampleCount(in: url) == 3)
    }

    @Test func discardsSegmentWithoutFrames() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mp4")
        let writer = try SegmentWriter(url: url, startDate: .now, size: size, captureIntervalSeconds: 1)
        await writer.finish()
        #expect(!FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
    }

    private func makePixelBuffer() throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attributes = [kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any]()] as CFDictionary
        CVPixelBufferCreate(nil, size.width, size.height, kCVPixelFormatType_32BGRA, attributes, &pixelBuffer)
        return try #require(pixelBuffer)
    }

    private func sampleCount(in url: URL) async throws -> Int {
        let asset = AVURLAsset(url: url)
        let track = try #require(try await asset.loadTracks(withMediaType: .video).first)
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        reader.add(output)
        reader.startReading()
        var count = 0
        while output.copyNextSampleBuffer() != nil {
            count += 1
        }
        return count
    }
}
