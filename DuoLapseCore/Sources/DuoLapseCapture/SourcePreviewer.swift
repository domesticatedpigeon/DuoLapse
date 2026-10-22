import CoreGraphics
import DuoLapseCore
import Foundation
import Observation

@Observable
public final class SourcePreviewer {
    public private(set) var screenImage: CGImage?
    public private(set) var cameraImage: CGImage?

    @ObservationIgnored private let renderer = PreviewRenderer()
    @ObservationIgnored private var camera: CameraFrameSource?

    public init() {}

    public func showPreviews(displayUUID: String?, cameraID: String?, refreshInterval: Duration = .seconds(1)) async {
        screenImage = nil
        cameraImage = nil
        await stopCamera()
        let previewCamera = await startedCamera(cameraID)
        camera = previewCamera
        while !Task.isCancelled {
            if let displayUUID {
                screenImage = await latestScreenImage(displayUUID: displayUUID) ?? screenImage
            }
            if let previewCamera, let pixelBuffer = try? previewCamera.currentFrame() {
                cameraImage = await renderer.image(from: PreviewFrame(pixelBuffer: pixelBuffer))
            }
            try? await Task.sleep(for: refreshInterval, tolerance: .milliseconds(200))
        }
        if camera === previewCamera {
            camera = nil
        }
        await previewCamera?.stop()
    }

    public func stopCamera() async {
        let runningCamera = camera
        camera = nil
        await runningCamera?.stop()
    }

    private func startedCamera(_ cameraID: String?) async -> CameraFrameSource? {
        guard let cameraID else { return nil }
        let camera = CameraFrameSource(deviceID: cameraID)
        do {
            try await camera.start()
            return camera
        } catch {
            await camera.stop()
            return nil
        }
    }

    private func latestScreenImage(displayUUID: String) async -> CGImage? {
        try? await ScreenFrameSource.capturePreviewImage(displayUUID: displayUUID)
    }
}
