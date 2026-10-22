import CoreGraphics
import CoreImage
import CoreVideo

nonisolated final class PreviewRenderer: @unchecked Sendable {
    private static let maximumLongEdge: CGFloat = 960

    private let context = CIContext(options: [.cacheIntermediates: false])

    @concurrent
    func image(from frame: PreviewFrame) async -> CGImage? {
        let image = CIImage(cvPixelBuffer: frame.pixelBuffer)
        let longEdge = max(image.extent.width, image.extent.height)
        guard longEdge > 0 else { return nil }
        let scale = min(1, Self.maximumLongEdge / longEdge)
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return context.createCGImage(scaled, from: scaled.extent)
    }
}

nonisolated struct PreviewFrame: @unchecked Sendable {
    let pixelBuffer: CVPixelBuffer
}
