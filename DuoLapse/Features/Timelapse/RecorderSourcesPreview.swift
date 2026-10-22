import DuoLapseCapture
import DuoLapseCore
import DuoLapseExport
import SwiftUI

struct RecorderSourcesPreview: View {
    let recorder: TimelapseRecorder
    let store: SessionStore
    var style = SourcesPreviewStyle.regular
    var switchingLibrary: TimelapseLibrary?
    var onSwitchError: (String) -> Void = { _ in }
    @State private var thumbnails = StoredThumbnails.shared
    @State private var devices = CaptureDevices.shared

    var body: some View {
        SourcesPreview(
            screenImage: image(for: .screen),
            cameraImage: image(for: .camera),
            style: style,
            screenChoices: displayChoices,
            cameraChoices: cameraChoices
        )
        .task(id: StoredThumbnails.key(for: recorder.session)) {
            await thumbnails.load(for: recorder.session, store: store)
        }
        .task {
            if switchingLibrary != nil {
                await devices.refresh()
            }
        }
    }

    private var displayChoices: [SourceChoice] {
        guard let library = switchingLibrary, recorder.session.isOpen,
            let current = recorder.session.settings.displayUUID
        else { return [] }
        var choices = devices.displays.map { display in
            SourceChoice(id: display.uuid, title: display.name, isSelected: display.uuid == current) {
                switchSource { try await library.switchDisplay(of: recorder, to: display.uuid) }
            }
        }
        if !devices.displays.contains(where: { $0.uuid == current }) {
            choices.append(SourceChoice(id: current, title: "Unavailable display", isSelected: true) {})
        }
        return choices
    }

    private var cameraChoices: [SourceChoice] {
        guard let library = switchingLibrary, recorder.session.isOpen,
            let current = recorder.session.settings.cameraID
        else { return [] }
        var choices = devices.cameras.map { camera in
            SourceChoice(id: camera.uniqueID, title: camera.name, isSelected: camera.uniqueID == current) {
                switchSource { try await library.switchCamera(of: recorder, to: camera.uniqueID) }
            }
        }
        if !devices.cameras.contains(where: { $0.uniqueID == current }) {
            choices.append(SourceChoice(id: current, title: "Unavailable camera", isSelected: true) {})
        }
        return choices
    }

    private func switchSource(_ change: @escaping @MainActor () async throws -> Void) {
        Task {
            do {
                try await change()
            } catch {
                onSwitchError(error.localizedDescription)
            }
        }
    }

    private func image(for source: CaptureSource) -> CGImage? {
        recorder.latestPreviews[source] ?? thumbnails.image(for: recorder.session.id, source: source)
    }

}

@Observable
final class StoredThumbnails {
    static let shared = StoredThumbnails()
    private static let maximumSide: Double = 960

    private var images: [UUID: [CaptureSource: CGImage]] = [:]
    @ObservationIgnored private var loadedKeys: [UUID: String] = [:]

    func image(for sessionID: UUID, source: CaptureSource) -> CGImage? {
        images[sessionID]?[source]
    }

    static func key(for session: TimelapseSession) -> String {
        "\(session.state)-\(session.settings.sources)"
    }

    func load(for session: TimelapseSession, store: SessionStore) async {
        let key = Self.key(for: session)
        guard loadedKeys[session.id] != key else { return }
        loadedKeys[session.id] = key
        var loaded: [CaptureSource: CGImage] = [:]
        for source in session.settings.sources {
            loaded[source] = await ThumbnailGenerator().thumbnail(
                for: session,
                source: source,
                store: store,
                maximumSize: CGSize(width: Self.maximumSide, height: Self.maximumSide)
            )
        }
        images[session.id] = loaded.merging(images[session.id] ?? [:]) { new, _ in new }
    }
}
