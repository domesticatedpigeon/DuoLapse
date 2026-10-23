import DuoLapseCore
import Foundation

public struct ExportSource: Sendable {
    public let session: TimelapseSession
    public let frames: [ExportFrame]
    public let screenSize: PixelSize?
    public let cameraSize: PixelSize?
    let screenSegments: [URL]
    let cameraSegments: [URL]
}

public enum ExportError: LocalizedError {
    case noFrames
    case missingFrame
    case cannotWriteVideo

    public var errorDescription: String? {
        switch self {
        case .noFrames: "This timelapse has no frames to export yet."
        case .missingFrame: "Some recorded frames couldn’t be read. The recording may be damaged."
        case .cannotWriteVideo:
            "DuoLapse couldn’t write the video file. Check that the folder is writable and has space."
        }
    }
}
