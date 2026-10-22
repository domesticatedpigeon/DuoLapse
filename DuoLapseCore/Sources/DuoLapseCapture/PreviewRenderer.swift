import CoreGraphics
import CoreImage
import CoreVideo

final class PreviewRenderer {
    private static let maximumLongEdge: CGFloat = 960

    private let context = CIContext(options: [.cacheIntermediates: false])

    func image(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let longEdge = max(image.extent.width, image.extent.height)
        guard longEdge > 0 else { return nil }
        let scale = min(1, Self.maximumLongEdge / longEdge)
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return context.createCGImage(scaled, from: scaled.extent)
    }
}
