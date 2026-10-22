import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct RecorderPreview: View {
    let recorder: TimelapseRecorder
    let store: SessionStore
    var contentMode: SwiftUI.ContentMode = .fill
    var showsCameraInset = false

    var body: some View {
        if let primaryImage {
            Rectangle()
                .fill(.black)
                .overlay {
                    Image(decorative: primaryImage, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                }
                .overlay(alignment: .bottomTrailing) {
                    if showsCameraInset, let cameraInset {
                        Image(decorative: cameraInset, scale: 1)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.25 }
                            .clipShape(.rect(cornerRadius: 6))
                            .padding(8)
                    }
                }
                .clipped()
                .accessibilityLabel("Latest captured frame")
        } else {
            TimelapseThumbnail(
                session: recorder.session,
                store: store,
                maximumSide: 960,
                contentMode: contentMode
            )
        }
    }

    private var primaryImage: CGImage? {
        recorder.latestPreviews[.screen] ?? recorder.latestPreviews[.camera]
    }

    private var cameraInset: CGImage? {
        recorder.latestPreviews[.screen] == nil ? nil : recorder.latestPreviews[.camera]
    }
}
