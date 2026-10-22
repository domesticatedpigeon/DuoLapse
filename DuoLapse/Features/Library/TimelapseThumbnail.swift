import DuoLapseCore
import DuoLapseExport
import SwiftUI

struct TimelapseThumbnail: View {
    let session: TimelapseSession
    let store: SessionStore
    let maximumSide: Double
    var contentMode: ContentMode = .fill
    @State private var image: CGImage?

    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                if let image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
            .clipped()
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
        "\(session.id)-\(session.state)"
    }
}
