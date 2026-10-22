import DuoLapseCore
import SwiftUI

struct CapturePreview: View {
    static let cameraInsetWidthFraction = 0.25

    let primaryImage: CGImage
    let cameraInset: CGImage?
    var contentMode: SwiftUI.ContentMode = .fit

    var body: some View {
        Image(decorative: primaryImage, scale: 1)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .overlay { cameraInsetLayer }
            .clipped()
    }

    var aspectRatio: CGFloat {
        primaryImage.height > 0 ? CGFloat(primaryImage.width) / CGFloat(primaryImage.height) : 16 / 10
    }

    @ViewBuilder private var cameraInsetLayer: some View {
        if let cameraInset {
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
}
