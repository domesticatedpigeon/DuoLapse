public enum ExportCodec: String, Codable, Sendable, CaseIterable {
    case hevc
    case h264
}

public struct ExportSettings: Hashable, Codable, Sendable {
    public var duration: ExportDuration
    public var layout: ExportLayout
    public var includesTimestamp: Bool
    public var codec: ExportCodec
    public var filenameTemplate: FilenameTemplate

    public init(
        duration: ExportDuration = .seconds(60),
        layout: ExportLayout = ExportLayout(),
        includesTimestamp: Bool = true,
        codec: ExportCodec = .hevc,
        filenameTemplate: FilenameTemplate = FilenameTemplate()
    ) {
        self.duration = duration
        self.layout = layout
        self.includesTimestamp = includesTimestamp
        self.codec = codec
        self.filenameTemplate = filenameTemplate
    }
}
