import CoreMedia
import CoreVideo
import DuoLapseCore
import Foundation
@preconcurrency import ScreenCaptureKit

enum ScreenFrameSource {
    static func captureFrame(displayUUID: String, resolution: StorageResolution) async throws -> CMSampleBuffer {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard
            let display = content.displays.first(where: { DisplayCatalog.uuidString(for: $0.displayID) == displayUUID })
        else {
            throw ScreenCaptureError.displayUnavailable
        }
        let size = resolution.screenStorageSize(for: DisplayCatalog.pixelSize(of: display))
        let configuration = SCStreamConfiguration()
        configuration.width = size.width
        configuration.height = size.height
        configuration.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        configuration.showsCursor = true
        let filter = SCContentFilter(display: display, excludingWindows: [])
        return try await SCScreenshotManager.captureSampleBuffer(contentFilter: filter, configuration: configuration)
    }

    static func capturePreviewImage(displayUUID: String) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard
            let display = content.displays.first(where: { DisplayCatalog.uuidString(for: $0.displayID) == displayUUID })
        else {
            throw ScreenCaptureError.displayUnavailable
        }
        let size = DisplayCatalog.pixelSize(of: display).fitting(longEdge: previewLongEdge)
        let configuration = SCStreamConfiguration()
        configuration.width = size.width
        configuration.height = size.height
        configuration.showsCursor = true
        let filter = SCContentFilter(display: display, excludingWindows: [])
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }

    private static let previewLongEdge = 640
}

nonisolated public enum ScreenCaptureError: LocalizedError {
    case displayUnavailable
    case frameMissingImage

    public var errorDescription: String? {
        switch self {
        case .displayUnavailable: "The selected display isn’t available. Check that it’s connected and awake."
        case .frameMissingImage: "The screenshot didn’t contain an image."
        }
    }
}
