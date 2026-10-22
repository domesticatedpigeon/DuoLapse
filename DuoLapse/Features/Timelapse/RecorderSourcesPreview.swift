import DuoLapseCapture
import DuoLapseCore
import DuoLapseExport
import SwiftUI

struct RecorderSourcesPreview: View {
    let recorder: TimelapseRecorder
    let store: SessionStore
    var style = SourcesPreviewStyle.regular
    var thumbnailSide: Double = 960
    @State private var storedThumbnails: [CaptureSource: CGImage] = [:]

    var body: some View {
        SourcesPreview(screenImage: image(for: .screen), cameraImage: image(for: .camera), style: style)
            .task(id: refreshKey) {
                await loadStoredThumbnails()
            }
    }

    private func image(for source: CaptureSource) -> CGImage? {
        recorder.latestPreviews[source] ?? storedThumbnails[source]
    }

    private var refreshKey: String {
        "\(recorder.session.id)-\(recorder.session.state)-\(recorder.session.settings.sources)"
    }

    private func loadStoredThumbnails() async {
        var thumbnails: [CaptureSource: CGImage] = [:]
        for source in recorder.session.settings.sources {
            thumbnails[source] = await ThumbnailGenerator().thumbnail(
                for: recorder.session,
                source: source,
                store: store,
                maximumSize: CGSize(width: thumbnailSide, height: thumbnailSide)
            )
        }
        storedThumbnails = thumbnails
    }
}
