import SwiftUI

struct SourcesPreviewStyle {
    static let regular = SourcesPreviewStyle(spacing: 8, cornerRadius: 8, placeholderSymbolFont: .title2)
    static let compact = SourcesPreviewStyle(spacing: 2, cornerRadius: 4, placeholderSymbolFont: .caption2)

    let spacing: CGFloat
    let cornerRadius: CGFloat
    let placeholderSymbolFont: Font
}

struct SourcesPreview: View {
    static let screenPlaceholderAspectRatio: CGFloat = 16 / 10
    static let cameraPlaceholderAspectRatio: CGFloat = 16 / 9

    let screenImage: CGImage?
    let cameraImage: CGImage?
    var style = SourcesPreviewStyle.regular

    var body: some View {
        EqualHeightRow(spacing: style.spacing) {
            slot(image: screenImage, placeholderSymbol: "display", label: "Screen")
                .layoutValue(
                    key: AspectRatioKey.self,
                    value: aspectRatio(of: screenImage) ?? Self.screenPlaceholderAspectRatio
                )
            slot(image: cameraImage, placeholderSymbol: "web.camera", label: "Camera")
                .layoutValue(
                    key: AspectRatioKey.self,
                    value: aspectRatio(of: cameraImage) ?? Self.cameraPlaceholderAspectRatio
                )
        }
    }

    @ViewBuilder
    private func slot(image: CGImage?, placeholderSymbol: String, label: String) -> some View {
        Group {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: placeholderSymbol)
                            .font(style.placeholderSymbolFont)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .clipShape(.rect(cornerRadius: style.cornerRadius))
        .accessibilityElement()
        .accessibilityLabel(image == nil ? "\(label), no preview" : label)
    }

    private func aspectRatio(of image: CGImage?) -> CGFloat? {
        guard let image, image.height > 0 else { return nil }
        return CGFloat(image.width) / CGFloat(image.height)
    }
}

nonisolated private struct AspectRatioKey: LayoutValueKey {
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
