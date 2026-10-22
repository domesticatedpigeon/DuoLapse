import DuoLapseCore
import DuoLapseExport
import SwiftUI

struct TimelapseThumbnail: View {
    let session: TimelapseSession
    let store: SessionStore
    let maximumSide: Double
    @State private var image: CGImage?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.quaternary)
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityHidden(true)
        .task(id: refreshKey) {
            image = await ThumbnailGenerator().thumbnail(
                for: session,
                store: store,
                maximumSize: CGSize(width: maximumSide, height: maximumSide)
            )
        }
    }

    private var refreshKey: String {
        "\(session.id)-\(session.state)-\(session.capturedFrameCount / 60)"
    }
}
