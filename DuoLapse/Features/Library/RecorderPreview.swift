import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct RecorderPreview: View {
    static let placeholderAspectRatio = 16.0 / 10.0

    let recorder: TimelapseRecorder
    let store: SessionStore
    var contentMode: SwiftUI.ContentMode = .fill

    var body: some View {
        if contentMode == .fit {
            preview.aspectRatio(livePreview?.aspectRatio ?? Self.placeholderAspectRatio, contentMode: .fit)
        } else {
            preview
        }
    }

    @ViewBuilder private var preview: some View {
        if let livePreview {
            livePreview.accessibilityLabel("Latest captured frame")
        } else {
            TimelapseThumbnail(
                session: recorder.session,
                store: store,
                maximumSide: 960,
                contentMode: contentMode
            )
        }
    }

    private var livePreview: CapturePreview? {
        guard let primaryImage = recorder.latestPreviews[.screen] ?? recorder.latestPreviews[.camera] else {
            return nil
        }
        return CapturePreview(primaryImage: primaryImage, contentMode: contentMode)
    }
}
