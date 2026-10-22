import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreVideo
import DuoLapseCore

final class FrameCompositor {
    private let plan: LayoutPlan
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    private var cachedTimestampBadge: (text: String, image: CIImage)?

    init(plan: LayoutPlan) {
        self.plan = plan
    }

    private var canvasWidth: Double {
        Double(plan.canvasSize.width)
    }

    private var canvasHeight: Double {
        Double(plan.canvasSize.height)
    }

    private var canvasRect: CGRect {
        CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)
    }

    func composite(screen: CVPixelBuffer?, camera: CVPixelBuffer?, timestamp: String?) -> CIImage {
        var image = CIImage(color: .black).cropped(to: canvasRect)
        if let screen, let placement = plan.screen {
            image = place(CIImage(cvPixelBuffer: screen), in: placement).composited(over: image)
        }
        if let camera, let placement = plan.camera {
            image = place(CIImage(cvPixelBuffer: camera), in: placement).composited(over: image)
        }
        if let timestamp {
            image = timestampBadge(timestamp).composited(over: image)
        }
        return image
    }

    func render(_ image: CIImage, to pixelBuffer: CVPixelBuffer) {
        context.render(image, to: pixelBuffer, bounds: canvasRect, colorSpace: colorSpace)
    }

    func makeCGImage(_ image: CIImage) -> CGImage? {
        context.createCGImage(image, from: canvasRect)
    }

    private func place(_ image: CIImage, in placement: Placement) -> CIImage {
        let target = coreImageRect(placement.frame)
        let extent = image.extent
        guard extent.width > 0, extent.height > 0 else { return .empty() }
        let widthScale = target.width / extent.width
        let heightScale = target.height / extent.height
        let scale = placement.contentMode == .fill ? max(widthScale, heightScale) : min(widthScale, heightScale)
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let centered =
            scaled
            .transformed(
                by: CGAffineTransform(
                    translationX: target.midX - scaled.extent.midX,
                    y: target.midY - scaled.extent.midY
                )
            )
            .cropped(to: target)
        guard placement.cornerRadius > 0 else { return centered }
        return centered.applyingFilter(
            "CIBlendWithMask",
            parameters: [
                kCIInputBackgroundImageKey: CIImage.empty(),
                kCIInputMaskImageKey: roundedRectangle(target, radius: placement.cornerRadius, color: .white),
            ]
        )
    }

    private func timestampBadge(_ text: String) -> CIImage {
        if let cachedTimestampBadge, cachedTimestampBadge.text == text {
            return cachedTimestampBadge.image
        }
        let fontSize = max(14, min(canvasWidth, canvasHeight) * 0.03)
        let generator = CIFilter.attributedTextImageGenerator()
        generator.text = NSAttributedString(
            string: text,
            attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: NSColor.white,
            ]
        )
        generator.scaleFactor = 1
        let textImage = generator.outputImage ?? .empty()
        let horizontalPadding = fontSize * 0.6
        let verticalPadding = fontSize * 0.3
        let badgeWidth = textImage.extent.width + horizontalPadding * 2
        let badgeHeight = textImage.extent.height + verticalPadding * 2
        let background = roundedRectangle(
            CGRect(x: 0, y: 0, width: badgeWidth, height: badgeHeight),
            radius: badgeHeight / 2,
            color: CIColor(red: 0, green: 0, blue: 0, alpha: 0.55)
        )
        let alignedText = textImage.transformed(
            by: CGAffineTransform(
                translationX: horizontalPadding - textImage.extent.minX,
                y: verticalPadding - textImage.extent.minY
            )
        )
        let margin = (canvasWidth * LayoutEngine.overlayMarginFraction).rounded()
        let corner = plan.timestampCorner
        let x = corner.isLeading ? margin : canvasWidth - margin - badgeWidth
        let y = corner.isTop ? canvasHeight - margin - badgeHeight : margin
        let badge = alignedText.composited(over: background).transformed(by: CGAffineTransform(translationX: x, y: y))
        cachedTimestampBadge = (text, badge)
        return badge
    }

    private func roundedRectangle(_ rect: CGRect, radius: Double, color: CIColor) -> CIImage {
        let generator = CIFilter.roundedRectangleGenerator()
        generator.extent = rect
        generator.radius = Float(radius)
        generator.color = color
        return generator.outputImage ?? .empty()
    }

    private func coreImageRect(_ rect: LayoutRect) -> CGRect {
        CGRect(x: rect.x, y: canvasHeight - rect.y - rect.height, width: rect.width, height: rect.height)
    }
}
