public enum ExportOrientation: String, Codable, Sendable, CaseIterable {
    case horizontal
    case vertical
}

public enum HorizontalArrangement: String, Codable, Sendable, CaseIterable {
    case pictureInPicture
    case sideBySide
}

public enum VerticalOrder: String, Codable, Sendable, CaseIterable {
    case screenOnTop
    case cameraOnTop
}

public enum OverlayCorner: String, Codable, Sendable, CaseIterable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    public var isTop: Bool {
        self == .topLeading || self == .topTrailing
    }

    public var isLeading: Bool {
        self == .topLeading || self == .bottomLeading
    }
}

public enum OverlaySize: String, Codable, Sendable, CaseIterable {
    case small
    case medium
    case large

    public var widthFraction: Double {
        switch self {
        case .small: 0.20
        case .medium: 0.25
        case .large: 0.33
        }
    }
}

public struct CameraOverlay: Hashable, Codable, Sendable {
    public static let maximumCornerRadiusFraction = 0.5
    public static let defaultCornerRadiusFraction = maximumCornerRadiusFraction * 0.2

    public var corner: OverlayCorner
    public var size: OverlaySize
    public var cornerRadiusFraction: Double
    public var isCircular: Bool

    public init(
        corner: OverlayCorner = .bottomTrailing,
        size: OverlaySize = .medium,
        cornerRadiusFraction: Double = CameraOverlay.defaultCornerRadiusFraction,
        isCircular: Bool = false
    ) {
        self.corner = corner
        self.size = size
        self.cornerRadiusFraction = cornerRadiusFraction
        self.isCircular = isCircular
    }
}

public enum SourceFraming: String, Codable, Sendable, CaseIterable {
    case fill
    case fit
}

public struct ExportLayout: Hashable, Codable, Sendable {
    public static let defaultVerticalScreenShare = 0.5
    public static let verticalScreenShareRange = 0.25...0.75

    public var orientation: ExportOrientation
    public var horizontalArrangement: HorizontalArrangement
    public var verticalOrder: VerticalOrder
    public var verticalScreenShare: Double
    public var screenFraming: SourceFraming
    public var cameraFraming: SourceFraming
    public var cameraOverlay: CameraOverlay

    public init(
        orientation: ExportOrientation = .horizontal,
        horizontalArrangement: HorizontalArrangement = .pictureInPicture,
        verticalOrder: VerticalOrder = .screenOnTop,
        verticalScreenShare: Double = ExportLayout.defaultVerticalScreenShare,
        screenFraming: SourceFraming = .fit,
        cameraFraming: SourceFraming = .fill,
        cameraOverlay: CameraOverlay = CameraOverlay()
    ) {
        self.orientation = orientation
        self.horizontalArrangement = horizontalArrangement
        self.verticalOrder = verticalOrder
        self.verticalScreenShare = verticalScreenShare
        self.screenFraming = screenFraming
        self.cameraFraming = cameraFraming
        self.cameraOverlay = cameraOverlay
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orientation = try container.decode(ExportOrientation.self, forKey: .orientation)
        horizontalArrangement = try container.decode(HorizontalArrangement.self, forKey: .horizontalArrangement)
        verticalOrder = try container.decode(VerticalOrder.self, forKey: .verticalOrder)
        verticalScreenShare =
            try container.decodeIfPresent(Double.self, forKey: .verticalScreenShare)
            ?? Self.defaultVerticalScreenShare
        screenFraming = try container.decodeIfPresent(SourceFraming.self, forKey: .screenFraming) ?? .fit
        cameraFraming = try container.decodeIfPresent(SourceFraming.self, forKey: .cameraFraming) ?? .fill
        cameraOverlay = try container.decode(CameraOverlay.self, forKey: .cameraOverlay)
    }
}
