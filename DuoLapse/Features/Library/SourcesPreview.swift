import SwiftUI

struct SourcesPreview: View {
    static let spacing: CGFloat = 8
    static let cornerRadius: CGFloat = 8

    let screenImage: CGImage?
    let cameraImage: CGImage?

    var body: some View {
        EqualHeightRow(spacing: Self.spacing) {
            if let screenImage {
                framedImage(screenImage)
                    .layoutValue(key: AspectRatioKey.self, value: aspectRatio(of: screenImage))
                    .accessibilityLabel("Screen")
            }
            if let cameraImage {
                framedImage(cameraImage)
                    .layoutValue(key: AspectRatioKey.self, value: aspectRatio(of: cameraImage))
                    .accessibilityLabel("Camera")
            }
        }
    }

    private func framedImage(_ image: CGImage) -> some View {
        Image(decorative: image, scale: 1)
            .resizable()
            .clipShape(.rect(cornerRadius: Self.cornerRadius))
    }

    private func aspectRatio(of image: CGImage) -> CGFloat {
        image.height > 0 ? CGFloat(image.width) / CGFloat(image.height) : 16 / 10
    }
}

private struct AspectRatioKey: LayoutValueKey {
    static let defaultValue: CGFloat = 16 / 10
}

private struct EqualHeightRow: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 640
        return CGSize(width: width, height: rowHeight(forWidth: width, subviews: subviews))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let height = rowHeight(forWidth: bounds.width, subviews: subviews)
        var x = bounds.minX
        for subview in subviews {
            let width = height * subview[AspectRatioKey.self]
            subview.place(
                at: CGPoint(x: x, y: bounds.minY),
                proposal: ProposedViewSize(width: width, height: height)
            )
            x += width + spacing
        }
    }

    private func rowHeight(forWidth width: CGFloat, subviews: Subviews) -> CGFloat {
        let totalAspectRatio = subviews.map { $0[AspectRatioKey.self] }.reduce(0, +)
        guard totalAspectRatio > 0 else { return 0 }
        let gaps = spacing * CGFloat(max(subviews.count - 1, 0))
        return max(width - gaps, 0) / totalAspectRatio
    }
}
