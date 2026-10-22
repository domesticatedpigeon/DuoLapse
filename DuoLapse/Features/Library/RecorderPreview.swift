import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct RecorderPreview: View {
    static let cameraInsetWidthFraction = 0.25
    static let placeholderAspectRatio = 16.0 / 10.0

    let recorder: TimelapseRecorder
    let store: SessionStore
    var contentMode: SwiftUI.ContentMode = .fill
    var showsCameraInset = false

    var body: some View {
        if contentMode == .fit {
            preview.aspectRatio(displayAspectRatio, contentMode: .fit)
        } else {
            preview
        }
    }

    @ViewBuilder private var preview: some View {
        if let primaryImage {
            Image(decorative: primaryImage, scale: 1)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
                .overlay { cameraInsetLayer }
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

    @ViewBuilder private var cameraInsetLayer: some View {
        if showsCameraInset, let cameraInset {
            GeometryReader { proxy in
                let margin = proxy.size.width * LayoutEngine.overlayMarginFraction
                Image(decorative: cameraInset, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: proxy.size.width * Self.cameraInsetWidthFraction)
                    .clipShape(.rect(cornerRadius: 6))
                    .padding(margin)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
    }

    private var primaryImage: CGImage? {
        recorder.latestPreviews[.screen] ?? recorder.latestPreviews[.camera]
    }

    private var cameraInset: CGImage? {
        recorder.latestPreviews[.screen] == nil ? nil : recorder.latestPreviews[.camera]
    }

    private var displayAspectRatio: CGFloat {
        guard let primaryImage, primaryImage.height > 0 else { return Self.placeholderAspectRatio }
        return CGFloat(primaryImage.width) / CGFloat(primaryImage.height)
    }
}
