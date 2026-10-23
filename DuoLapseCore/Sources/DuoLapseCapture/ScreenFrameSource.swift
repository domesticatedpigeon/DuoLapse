import CoreMedia
import CoreVideo
import DuoLapseCore
import Foundation
@preconcurrency import ScreenCaptureKit

enum ScreenFrameSource {
    static func captureFrame(displayUUID: String, resolution: StorageResolution) async throws -> CMSampleBuffer {
        let display = try await display(for: displayUUID)
        let size = resolution.screenStorageSize(for: DisplayCatalog.pixelSize(of: display))
        let configuration = SCStreamConfiguration()
        configuration.width = size.width
        configuration.height = size.height
        configuration.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        configuration.showsCursor = true
        let filter = SCContentFilter(display: display, excludingWindows: [])
        do {
            return try await SCScreenshotManager.captureSampleBuffer(
                contentFilter: filter, configuration: configuration)
        } catch {
            forgetDisplays()
            throw error
        }
    }

    static func capturePreviewImage(displayUUID: String) async throws -> CGImage {
        let display = try await display(for: displayUUID)
        let size = DisplayCatalog.pixelSize(of: display).fitting(longEdge: previewLongEdge)
        let configuration = SCStreamConfiguration()
        configuration.width = size.width
        configuration.height = size.height
        configuration.showsCursor = true
        let filter = SCContentFilter(display: display, excludingWindows: [])
        do {
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
        } catch {
            forgetDisplays()
            throw error
        }
    }

    private static let previewLongEdge = 640
    private static var displaysByUUID: [String: SCDisplay] = [:]

    private static func display(for uuid: String) async throws -> SCDisplay {
        if let display = displaysByUUID[uuid] {
            return display
        }
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        displaysByUUID = Dictionary(
            content.displays.compactMap { display in
                DisplayCatalog.uuidString(for: display.displayID).map { ($0, display) }
            },
            uniquingKeysWith: { first, _ in first }
        )
        guard let display = displaysByUUID[uuid] else { throw ScreenCaptureError.displayUnavailable }
        return display
    }

    static func forgetDisplays() {
        displaysByUUID = [:]
    }
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
