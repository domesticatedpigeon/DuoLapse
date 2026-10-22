import CoreGraphics
import DuoLapseCore
import Foundation
import Observation

@Observable
public final class SourcePreviewer {
    public static let shared = SourcePreviewer()

    private var screenImages: [String: CGImage] = [:]
    private var cameraImages: [String: CGImage] = [:]

    @ObservationIgnored private let renderer = PreviewRenderer()
    @ObservationIgnored private var camera: CameraFrameSource?

    public init() {}

    public func screenImage(forDisplay uuid: String) -> CGImage? {
        screenImages[uuid]
    }

    public func cameraImage(forCamera id: String) -> CGImage? {
        cameraImages[id]
    }

    public func showPreviews(displayUUID: String?, cameraID: String?, refreshInterval: Duration = .seconds(1)) async {
        if let displayUUID {
            await refreshScreenImage(displayUUID: displayUUID)
        }
        await stopCamera()
        let previewCamera = await startedCamera(cameraID)
        camera = previewCamera
        while !Task.isCancelled {
            if let displayUUID {
                await refreshScreenImage(displayUUID: displayUUID)
            }
            if let cameraID, let previewCamera, let pixelBuffer = try? previewCamera.currentFrame() {
                cameraImages[cameraID] = await renderer.image(from: PreviewFrame(pixelBuffer: pixelBuffer))
            }
            try? await Task.sleep(for: refreshInterval, tolerance: .milliseconds(200))
        }
        if camera === previewCamera {
            camera = nil
        }
        await previewCamera?.stop()
    }

    public func refreshScreenImage(displayUUID: String) async {
        if let image = try? await ScreenFrameSource.capturePreviewImage(displayUUID: displayUUID) {
            screenImages[displayUUID] = image
        }
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
}
