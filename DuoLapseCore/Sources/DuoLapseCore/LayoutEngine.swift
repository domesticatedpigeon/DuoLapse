public struct LayoutRect: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public enum ContentMode: Sendable {
    case fit
    case fill
}

extension SourceFraming {
    public var contentMode: ContentMode {
        switch self {
        case .fill: .fill
        case .fit: .fit
        }
    }
}

public struct Placement: Hashable, Sendable {
    public let frame: LayoutRect
    public let contentMode: ContentMode
    public let cornerRadius: Double
}

public struct LayoutPlan: Hashable, Sendable {
    public let canvasSize: PixelSize
    public let screen: Placement?
    public let camera: Placement?
    public let timestampCorner: OverlayCorner
}

extension Placement {
    static let matchingAspectRatioTolerance = 0.01

    public func framingMatters(forSourceOfSize size: PixelSize) -> Bool {
        guard size.width > 0, size.height > 0, frame.width > 0, frame.height > 0 else { return false }
        let sourceAspectRatio = Double(size.width) / Double(size.height)
        let frameAspectRatio = frame.width / frame.height
        return abs(sourceAspectRatio / frameAspectRatio - 1) > Self.matchingAspectRatioTolerance
    }
}

public enum LayoutEngine {
    static let defaultCameraAspectRatio = 9.0 / 16.0
    public static let overlayMarginFraction = 0.025

    public static func plan(
        layout: ExportLayout,
        screenSize: PixelSize?,
        cameraSize: PixelSize?,
        longEdge: Int
    ) -> LayoutPlan {
        switch layout.orientation {
        case .horizontal:
            horizontalPlan(layout: layout, screenSize: screenSize, cameraSize: cameraSize, longEdge: longEdge)
        case .vertical: verticalPlan(layout: layout, screenSize: screenSize, cameraSize: cameraSize, longEdge: longEdge)
        }
    }

    private static func horizontalPlan(
        layout: ExportLayout,
        screenSize: PixelSize?,
        cameraSize: PixelSize?,
        longEdge: Int
    ) -> LayoutPlan {
        let reference = screenSize ?? cameraSize ?? PixelSize(width: 16, height: 9)
        let canvas = PixelSize(width: longEdge, height: evenDimension(Double(longEdge) * aspectRatio(of: reference)))
        let fullCanvas = LayoutRect(x: 0, y: 0, width: Double(canvas.width), height: Double(canvas.height))

        guard screenSize != nil, let cameraSize else {
            return LayoutPlan(
                canvasSize: canvas,
                screen: screenSize.map { _ in
                    Placement(frame: fullCanvas, contentMode: layout.screenFraming.contentMode, cornerRadius: 0)
                },
                camera: cameraSize.map { _ in
                    Placement(frame: fullCanvas, contentMode: layout.cameraFraming.contentMode, cornerRadius: 0)
                },
                timestampCorner: .topTrailing
            )
        }

        switch layout.horizontalArrangement {
        case .pictureInPicture:
            let overlay = layout.cameraOverlay
            return LayoutPlan(
                canvasSize: canvas,
                screen: Placement(frame: fullCanvas, contentMode: layout.screenFraming.contentMode, cornerRadius: 0),
                camera: overlayPlacement(overlay, cameraSize: cameraSize, canvas: canvas),
                timestampCorner: overlay.corner == .topTrailing ? .topLeading : .topTrailing
            )
        case .sideBySide:
            return sideBySidePlan(
                layout: layout, screenSize: screenSize ?? reference, cameraSize: cameraSize, longEdge: longEdge)
        }
    }

    private static func sideBySidePlan(
        layout: ExportLayout, screenSize: PixelSize, cameraSize: PixelSize, longEdge: Int
    ) -> LayoutPlan {
        let widthPerHeight = 1 / aspectRatio(of: screenSize) + 1 / aspectRatio(of: cameraSize)
        let canvas = PixelSize(width: longEdge, height: evenDimension(Double(longEdge) / widthPerHeight))
        let height = Double(canvas.height)
        let screenWidth = (height / aspectRatio(of: screenSize)).rounded()
        return LayoutPlan(
            canvasSize: canvas,
            screen: Placement(
                frame: LayoutRect(x: 0, y: 0, width: screenWidth, height: height),
                contentMode: layout.screenFraming.contentMode,
                cornerRadius: 0
            ),
            camera: Placement(
                frame: LayoutRect(x: screenWidth, y: 0, width: Double(canvas.width) - screenWidth, height: height),
                contentMode: layout.cameraFraming.contentMode,
                cornerRadius: 0
            ),
            timestampCorner: .topLeading
        )
    }

    private static func verticalPlan(
        layout: ExportLayout,
        screenSize: PixelSize?,
        cameraSize: PixelSize?,
        longEdge: Int
    ) -> LayoutPlan {
        let canvas = PixelSize(width: evenDimension(Double(longEdge) * 9 / 16), height: longEdge)
        let width = Double(canvas.width)
        let height = Double(canvas.height)
        let fullCanvas = LayoutRect(x: 0, y: 0, width: width, height: height)

        guard screenSize != nil, cameraSize != nil else {
            return LayoutPlan(
                canvasSize: canvas,
                screen: screenSize.map { _ in
                    Placement(frame: fullCanvas, contentMode: layout.screenFraming.contentMode, cornerRadius: 0)
                },
                camera: cameraSize.map { _ in
                    Placement(frame: fullCanvas, contentMode: layout.cameraFraming.contentMode, cornerRadius: 0)
                },
                timestampCorner: .topTrailing
            )
        }

        let range = ExportLayout.verticalScreenShareRange
        let screenShare = min(max(layout.verticalScreenShare, range.lowerBound), range.upperBound)
        let screenHeight = (height * screenShare).rounded()
        let cameraHeight = height - screenHeight
        let screenOnTop = layout.verticalOrder == .screenOnTop
        return LayoutPlan(
            canvasSize: canvas,
            screen: Placement(
                frame: LayoutRect(x: 0, y: screenOnTop ? 0 : cameraHeight, width: width, height: screenHeight),
                contentMode: layout.screenFraming.contentMode,
                cornerRadius: 0
            ),
            camera: Placement(
                frame: LayoutRect(x: 0, y: screenOnTop ? screenHeight : 0, width: width, height: cameraHeight),
                contentMode: layout.cameraFraming.contentMode,
                cornerRadius: 0
            ),
            timestampCorner: .topTrailing
        )
    }

    private static func overlayPlacement(_ overlay: CameraOverlay, cameraSize: PixelSize, canvas: PixelSize)
        -> Placement
    {
        let canvasWidth = Double(canvas.width)
        let canvasHeight = Double(canvas.height)
        let margin = (canvasWidth * overlayMarginFraction).rounded()
        let width = (canvasWidth * overlay.size.widthFraction).rounded()
        let height = overlay.isCircular ? width : (width * aspectRatio(of: cameraSize)).rounded()
        let radiusFraction =
            overlay.isCircular
            ? CameraOverlay.maximumCornerRadiusFraction
            : min(max(overlay.cornerRadiusFraction, 0), CameraOverlay.maximumCornerRadiusFraction)
        return Placement(
            frame: LayoutRect(
                x: overlay.corner.isLeading ? margin : canvasWidth - margin - width,
                y: overlay.corner.isTop ? margin : canvasHeight - margin - height,
                width: width,
                height: height
            ),
            contentMode: .fill,
            cornerRadius: min(width, height) * radiusFraction
        )
    }

    private static func aspectRatio(of size: PixelSize) -> Double {
        size.width > 0 ? Double(size.height) / Double(size.width) : defaultCameraAspectRatio
    }

    private static func evenDimension(_ value: Double) -> Int {
        max(2, Int((value / 2).rounded()) * 2)
    }
}
