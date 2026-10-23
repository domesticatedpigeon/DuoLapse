@preconcurrency import AVFoundation
import CoreMedia
import DuoLapseCore
import Foundation

enum SegmentFrameIndex {
    static func captureDates(in segments: [URL]) async throws -> [Date] {
        var dates: [Date] = []
        for segment in segments {
            guard let startDate = SegmentFile.startDate(ofSegmentNamed: segment.lastPathComponent) else { continue }
            let asset = AVURLAsset(url: segment)
            guard let track = try await asset.loadTracks(withMediaType: .video).first else { continue }
            let reader = try AVAssetReader(asset: asset)
            let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
            reader.add(output)
            guard reader.startReading() else { continue }
            while let sampleBuffer = output.copyNextSampleBuffer() {
                guard sampleBuffer.numSamples > 0 else { continue }
                dates.append(startDate.addingTimeInterval(sampleBuffer.presentationTimeStamp.seconds))
            }
        }
        return dates
    }

    static func frameSize(of segments: [URL]) async throws -> PixelSize? {
        guard let firstSegment = segments.first else { return nil }
        let asset = AVURLAsset(url: firstSegment)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { return nil }
        let size = try await track.load(.naturalSize)
        return PixelSize(width: Int(size.width.rounded()), height: Int(size.height.rounded()))
    }
}
