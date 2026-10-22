import Foundation
import Testing

@testable import DuoLapseCore

struct SessionStoreTests {
    let store = SessionStore(
        rootDirectory: FileManager.default.temporaryDirectory.appending(
            path: "DuoLapseTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
    )

    let session = TimelapseSession(
        createdAt: Date(timeIntervalSince1970: 1_761_150_000),
        state: .recording,
        settings: CaptureSettings(captureIntervalSeconds: 5, displayUUID: "DISPLAY", storageResolution: .standard)
    )

    @Test func savedSessionLoadsBackUnchanged() throws {
        defer { try? FileManager.default.removeItem(at: store.rootDirectory) }
        try store.save(session)
        #expect(try store.load(id: session.id) == session)
    }

    @Test func savingCreatesScreenSegmentsDirectory() throws {
        defer { try? FileManager.default.removeItem(at: store.rootDirectory) }
        try store.save(session)
        var isDirectory: ObjCBool = false
        let path = store.screenSegmentsDirectory(for: session.id).path(percentEncoded: false)
        #expect(FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
    }

    @Test func listsOnlySegmentsInStartOrder() throws {
        defer { try? FileManager.default.removeItem(at: store.rootDirectory) }
        try store.save(session)
        let directory = store.screenSegmentsDirectory(for: session.id)
        for name in ["1761150600000.mp4", "1761150000000.mp4", "stray.txt"] {
            try Data().write(to: directory.appending(path: name))
        }
        let segmentNames = store.screenSegments(of: session.id).map(\.lastPathComponent)
        #expect(segmentNames == ["1761150000000.mp4", "1761150600000.mp4"])
    }

    @Test func diskUsageSumsAllFiles() throws {
        defer { try? FileManager.default.removeItem(at: store.rootDirectory) }
        try store.save(session)
        let manifestSize = store.diskUsage(of: session.id)
        let segment = store.screenSegmentsDirectory(for: session.id).appending(path: "1761150000000.mp4")
        try Data(count: 1000).write(to: segment)
        #expect(store.diskUsage(of: session.id) == manifestSize + 1000)
    }

    @Test func diskUsageOfMissingSessionIsZero() {
        #expect(store.diskUsage(of: UUID()) == 0)
    }
}
