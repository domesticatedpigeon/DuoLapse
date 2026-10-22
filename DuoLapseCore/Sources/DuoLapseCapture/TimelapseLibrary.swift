import DuoLapseCore
import Foundation
import Observation

@Observable
public final class TimelapseLibrary {
    public let store: SessionStore
    public private(set) var recorders: [TimelapseRecorder] = []
    public private(set) var interruptedRecorder: TimelapseRecorder?
    public private(set) var heartbeat = Date.now

    @ObservationIgnored private let sleepAssertion = SleepAssertion()
    @ObservationIgnored private var hasLoaded = false

    public init(store: SessionStore) {
        self.store = store
    }

    public var openRecorders: [TimelapseRecorder] {
        recorders.filter { $0.session.isOpen }
    }

    public var closedRecorders: [TimelapseRecorder] {
        recorders.filter { !$0.session.isOpen }
    }

    public var hasRecordingInProgress: Bool {
        recorders.contains { $0.session.state == .recording || $0.session.state == .idlePaused }
    }

    public var activeRecorder: TimelapseRecorder? {
        recorders.first { $0.isCapturing }
    }

    public func recorder(for id: UUID) -> TimelapseRecorder? {
        recorders.first { $0.session.id == id }
    }

    public func reload() {
        let loadedIDs = Set(recorders.map { $0.session.id })
        let unloadedSessions = store.loadAll().filter { !loadedIDs.contains($0.id) }
        let interruptedID =
            hasLoaded ? nil : unloadedSessions.first { $0.state == .recording || $0.state == .idlePaused }?.id
        let newRecorders = unloadedSessions.map {
            TimelapseRecorder(session: Self.recoveredFromInterruptedRecording($0, store: store), store: store)
        }
        recorders = (recorders + newRecorders).sorted { $0.session.createdAt > $1.session.createdAt }
        interruptedRecorder = interruptedID.flatMap { recorder(for: $0) }
        hasLoaded = true
    }

    public var latestPausedRecorder: TimelapseRecorder? {
        recentlyPausedRecorders(limit: 1).first
    }

    public func recentlyPausedRecorders(limit: Int) -> [TimelapseRecorder] {
        Array(
            openRecorders
                .filter { $0.session.state.canResume }
                .sorted { $0.session.updatedAt > $1.session.updatedAt }
                .prefix(limit)
        )
    }

    public func dismissInterruptedRecording() {
        interruptedRecorder = nil
    }

    public func superviseRecording() async {
        while !Task.isCancelled {
            await applyRecordingPolicy()
            if hasRecordingInProgress {
                heartbeat = .now
            }
            try? await Task.sleep(for: .seconds(hasRecordingInProgress ? 1 : 5), tolerance: .milliseconds(500))
        }
        sleepAssertion.hold(false)
    }

    public func pauseAllForTermination() async {
        for recorder in recorders where recorder.session.state == .recording || recorder.session.state == .idlePaused {
            try? await recorder.pause()
        }
        sleepAssertion.hold(false)
    }

    private func applyRecordingPolicy() async {
        sleepAssertion.hold(
            RecordingPolicy.shouldPreventSleep(
                states: recorders.map { $0.session.state },
                isKeepAwakeEnabled: RecordingPreferences.isKeepAwakeEnabled
            )
        )
        let idleSeconds = UserActivity.secondsSinceLastInput
        for recorder in recorders {
            let action = RecordingPolicy.idleAction(
                for: recorder.session.state,
                idleSeconds: idleSeconds,
                isSmartPauseEnabled: RecordingPreferences.isSmartPauseEnabled
            )
            switch action {
            case .pauseForIdle:
                try? await recorder.pauseForIdle()
            case .resumeFromIdle:
                try? await record(recorder)
            case .none:
                break
            }
        }
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

    public func switchDisplay(of recorder: TimelapseRecorder, to uuid: String) async throws {
        try await recorder.changeCaptureSettings(to: recorder.session.settings.switchingDisplay(to: uuid))
    }

    public func switchCamera(of recorder: TimelapseRecorder, to id: String) async throws {
        try await recorder.changeCaptureSettings(to: recorder.session.settings.switchingCamera(to: id))
    }

    public func rename(_ recorder: TimelapseRecorder, to name: String) throws {
        try recorder.rename(to: name)
    }

    public func reopen(_ recorder: TimelapseRecorder) throws {
        try recorder.reopen()
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
        guard session.state == .recording || session.state == .idlePaused else { return session }
        var recovered = session
        recovered.state = .paused
        recovered.updatedAt = .now
        try? store.save(recovered)
        return recovered
    }
}
