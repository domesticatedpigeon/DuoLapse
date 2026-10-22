import DuoLapseCapture
import DuoLapseCore
import DuoLapseExport
import SwiftUI

struct RecorderSourcesPreview: View {
    let recorder: TimelapseRecorder
    let store: SessionStore
    var style = SourcesPreviewStyle.regular
    @State private var thumbnails = StoredThumbnails.shared

    var body: some View {
        SourcesPreview(screenImage: image(for: .screen), cameraImage: image(for: .camera), style: style)
            .task(id: thumbnailKey) {
                await thumbnails.load(for: recorder.session, store: store, key: thumbnailKey)
            }
    }

    private func image(for source: CaptureSource) -> CGImage? {
        recorder.latestPreviews[source] ?? thumbnails.image(for: recorder.session.id, source: source)
    }

    private var thumbnailKey: String {
        "\(recorder.session.state)-\(recorder.session.settings.sources)"
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

    func load(for session: TimelapseSession, store: SessionStore, key: String) async {
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
