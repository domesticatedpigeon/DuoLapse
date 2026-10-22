import DuoLapseCore
import Foundation
import Observation

@Observable
public final class TimelapseLibrary {
    public let store: SessionStore
    public private(set) var recorders: [TimelapseRecorder] = []

    public init(store: SessionStore) {
        self.store = store
    }

    public var openRecorders: [TimelapseRecorder] {
        recorders.filter { $0.session.isOpen }
    }

    public var closedRecorders: [TimelapseRecorder] {
        recorders.filter { !$0.session.isOpen }
    }

    public var activeRecorder: TimelapseRecorder? {
        recorders.first { $0.isCapturing }
    }

    public func recorder(for id: UUID) -> TimelapseRecorder? {
        recorders.first { $0.session.id == id }
    }

    public func reload() {
        let loadedIDs = Set(recorders.map { $0.session.id })
        let newRecorders = store.loadAll()
            .filter { !loadedIDs.contains($0.id) }
            .map { TimelapseRecorder(session: Self.recoveredFromInterruptedRecording($0, store: store), store: store) }
        recorders = (recorders + newRecorders).sorted { $0.session.createdAt > $1.session.createdAt }
    }

    public func startNewTimelapse(settings: CaptureSettings) async throws -> UUID {
        let session = TimelapseSession(state: .paused, settings: settings)
        try store.save(session)
        let recorder = TimelapseRecorder(session: session, store: store)
        recorders.insert(recorder, at: 0)
        try await record(recorder)
        return session.id
    }

    public func record(_ recorder: TimelapseRecorder) async throws {
        for other in recorders where other !== recorder && other.isCapturing {
            try await other.pause()
        }
        try await recorder.record()
    }

    public func pause(_ recorder: TimelapseRecorder) async throws {
        try await recorder.pause()
    }

    public func stop(_ recorder: TimelapseRecorder) async throws {
        try await recorder.stop()
    }

    public func moveToTrash(_ recorder: TimelapseRecorder) async throws {
        if recorder.isCapturing {
            try await recorder.pause()
        }
        try FileManager.default.trashItem(at: store.directory(for: recorder.session.id), resultingItemURL: nil)
        recorders.removeAll { $0 === recorder }
    }

    private static func recoveredFromInterruptedRecording(
        _ session: TimelapseSession,
        store: SessionStore
    ) -> TimelapseSession {
        guard session.state == .recording else { return session }
        var recovered = session
        recovered.state = .paused
        recovered.updatedAt = .now
        try? store.save(recovered)
        return recovered
    }
}
