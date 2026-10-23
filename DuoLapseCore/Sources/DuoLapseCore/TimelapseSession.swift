import Foundation

public struct TimelapseSession: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public var updatedAt: Date
    public var state: TimelapseState
    public var settings: CaptureSettings
    public var recordedSeconds: Double
    public var capturedFrameCount: Int
    public private(set) var name: String?

    public init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        state: TimelapseState,
        settings: CaptureSettings,
        recordedSeconds: Double = 0,
        capturedFrameCount: Int = 0,
        name: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.state = state
        self.settings = settings
        self.recordedSeconds = recordedSeconds
        self.capturedFrameCount = capturedFrameCount
        self.name = Self.normalizedName(name)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        state = try container.decode(TimelapseState.self, forKey: .state)
        settings = try container.decode(CaptureSettings.self, forKey: .settings)
        recordedSeconds = try container.decodeIfPresent(Double.self, forKey: .recordedSeconds) ?? 0
        capturedFrameCount = try container.decodeIfPresent(Int.self, forKey: .capturedFrameCount) ?? 0
        name = Self.normalizedName(try container.decodeIfPresent(String.self, forKey: .name))
    }

    public mutating func rename(to newName: String) {
        name = Self.normalizedName(newName)
    }

    private static func normalizedName(_ name: String?) -> String? {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    public var isOpen: Bool {
        state != .finished
    }
}
