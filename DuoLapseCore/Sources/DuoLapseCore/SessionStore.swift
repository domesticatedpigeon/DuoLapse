import Foundation

public struct SessionStore: Sendable {
    public let rootDirectory: URL

    public init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    public static func inApplicationSupport() throws -> SessionStore {
        let applicationSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return SessionStore(
            rootDirectory: applicationSupport.appending(path: "DuoLapse/Sessions", directoryHint: .isDirectory)
        )
    }

    public func directory(for id: UUID) -> URL {
        rootDirectory.appending(path: id.uuidString, directoryHint: .isDirectory)
    }

    public func segmentsDirectory(for id: UUID, source: CaptureSource) -> URL {
        directory(for: id).appending(path: source.rawValue, directoryHint: .isDirectory)
    }

    public func save(_ session: TimelapseSession) throws {
        let segmentDirectories = session.settings.sources.map { segmentsDirectory(for: session.id, source: $0) }
        let directories = [directory(for: session.id)] + segmentDirectories
        for directory in directories {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try Self.encoder.encode(session).write(to: manifestURL(for: session.id), options: .atomic)
    }

    public func load(id: UUID) throws -> TimelapseSession {
        try Self.decoder.decode(TimelapseSession.self, from: Data(contentsOf: manifestURL(for: id)))
    }

    public func loadAll() -> [TimelapseSession] {
        let directories =
            (try? FileManager.default.contentsOfDirectory(at: rootDirectory, includingPropertiesForKeys: nil)) ?? []
        return
            directories
            .compactMap { UUID(uuidString: $0.lastPathComponent) }
            .compactMap { try? load(id: $0) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    public func segments(of id: UUID, source: CaptureSource) -> [URL] {
        let contents =
            (try? FileManager.default.contentsOfDirectory(
                at: segmentsDirectory(for: id, source: source),
                includingPropertiesForKeys: nil
            )) ?? []
        return
            contents
            .compactMap { url in SegmentFile.startDate(ofSegmentNamed: url.lastPathComponent).map { (url, $0) } }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    public func diskUsage(of id: UUID) -> Int {
        guard
            let enumerator = FileManager.default.enumerator(
                at: directory(for: id),
                includingPropertiesForKeys: [.fileSizeKey]
            )
        else {
            return 0
        }
        return enumerator.reduce(0) { total, element in
            guard let url = element as? URL else { return total }
            return total + ((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
    }

    private func manifestURL(for id: UUID) -> URL {
        directory(for: id).appending(path: "session.json", directoryHint: .notDirectory)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
