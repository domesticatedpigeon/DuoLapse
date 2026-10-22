import Foundation

public struct TimelapseSession: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public var updatedAt: Date
    public var state: TimelapseState
    public var settings: CaptureSettings

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        state: TimelapseState,
        settings: CaptureSettings
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.state = state
        self.settings = settings
    }
}
