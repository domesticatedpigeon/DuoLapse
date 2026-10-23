@preconcurrency import AVFoundation
import CoreGraphics
import DuoLapseCore
import Foundation

public struct ThumbnailGenerator: Sendable {
    public init() {}

    @concurrent
    public func thumbnail(
        for session: TimelapseSession,
        store: SessionStore,
        maximumSize: CGSize
    ) async -> sending CGImage? {
        let latestSegment =
            store.segments(of: session.id, source: .screen).last
            ?? store.segments(of: session.id, source: .camera).last
        guard let latestSegment else { return nil }
        return await firstFrame(of: latestSegment, maximumSize: maximumSize)
    }

    @concurrent
    public func thumbnail(
        for session: TimelapseSession,
        source: CaptureSource,
        store: SessionStore,
        maximumSize: CGSize
    ) async -> sending CGImage? {
        guard let latestSegment = store.segments(of: session.id, source: source).last else { return nil }
        return await firstFrame(of: latestSegment, maximumSize: maximumSize)
    }

    private func firstFrame(of segment: URL, maximumSize: CGSize) async -> sending CGImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: segment))
        generator.maximumSize = maximumSize
        generator.appliesPreferredTrackTransform = true
        return try? await generator.image(at: .zero).image
    }
}
