import Foundation

public struct ExportFrame: Hashable, Sendable {
    public let capturedAt: Date
    public let screenFrameIndex: Int?
    public let cameraFrameIndex: Int?

    public init(capturedAt: Date, screenFrameIndex: Int?, cameraFrameIndex: Int?) {
        self.capturedAt = capturedAt
        self.screenFrameIndex = screenFrameIndex
        self.cameraFrameIndex = cameraFrameIndex
    }
}

public enum FrameTimeline {
    public static func frames(screen: [Date], camera: [Date], tolerance: TimeInterval) -> [ExportFrame] {
        var frames: [ExportFrame] = []
        var screenIndex = 0
        var cameraIndex = 0
        var latestScreenIndex: Int?
        var latestCameraIndex: Int?

        while screenIndex < screen.count || cameraIndex < camera.count {
            let nextScreen = screenIndex < screen.count ? screen[screenIndex] : nil
            let nextCamera = cameraIndex < camera.count ? camera[cameraIndex] : nil
            let capturedAt: Date

            if let nextScreen, let nextCamera, abs(nextScreen.timeIntervalSince(nextCamera)) <= tolerance {
                capturedAt = nextScreen
                latestScreenIndex = screenIndex
                latestCameraIndex = cameraIndex
                screenIndex += 1
                cameraIndex += 1
            } else if let nextScreen, nextCamera.map({ nextScreen < $0 }) ?? true {
                capturedAt = nextScreen
                latestScreenIndex = screenIndex
                screenIndex += 1
            } else if let nextCamera {
                capturedAt = nextCamera
                latestCameraIndex = cameraIndex
                cameraIndex += 1
            } else {
                break
            }

            frames.append(
                ExportFrame(
                    capturedAt: capturedAt,
                    screenFrameIndex: latestScreenIndex,
                    cameraFrameIndex: latestCameraIndex
                )
            )
        }
        return frames
    }
}
