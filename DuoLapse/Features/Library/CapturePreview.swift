import SwiftUI

struct CapturePreview: View {
    let primaryImage: CGImage
    var contentMode: SwiftUI.ContentMode = .fit

    var body: some View {
        Image(decorative: primaryImage, scale: 1)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .clipped()
    }

    var aspectRatio: CGFloat {
        primaryImage.height > 0 ? CGFloat(primaryImage.width) / CGFloat(primaryImage.height) : 16 / 10
    }
}
