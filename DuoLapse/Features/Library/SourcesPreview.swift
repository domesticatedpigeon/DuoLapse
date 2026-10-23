import SwiftUI

struct SourcesPreviewStyle {
    static let regular = SourcesPreviewStyle(spacing: 8, cornerRadius: 8, placeholderSymbolFont: .title2)
    static let compact = SourcesPreviewStyle(spacing: 2, cornerRadius: 4, placeholderSymbolFont: .caption2)

    let spacing: CGFloat
    let cornerRadius: CGFloat
    let placeholderSymbolFont: Font
}

struct SourceChoice: Identifiable {
    let id: String
    let title: String
    let isSelected: Bool
    let select: () -> Void
}

struct SourcesPreview: View {
    static let slotAspectRatio: CGFloat = 16 / 9

    let screenImage: CGImage?
    let cameraImage: CGImage?
    var style = SourcesPreviewStyle.regular
    var screenChoices: [SourceChoice] = []
    var cameraChoices: [SourceChoice] = []

    var body: some View {
        EqualSlotsRow(spacing: style.spacing, slotAspectRatio: Self.slotAspectRatio) {
            selectableSlot(
                image: screenImage,
                contentMode: .fit,
                placeholderSymbol: "display",
                label: "Screen",
                choices: screenChoices
            )
            selectableSlot(
                image: cameraImage,
                contentMode: .fill,
                placeholderSymbol: "web.camera",
                label: "Camera",
                choices: cameraChoices
            )
        }
    }

    @ViewBuilder
    private func selectableSlot(
        image: CGImage?,
        contentMode: ContentMode,
        placeholderSymbol: String,
        label: String,
        choices: [SourceChoice]
    ) -> some View {
        if choices.isEmpty {
            slot(image: image, contentMode: contentMode, placeholderSymbol: placeholderSymbol, label: label)
        } else {
            Menu {
                ForEach(choices) { choice in
                    Button(action: choice.select) {
                        if choice.isSelected {
                            Label(choice.title, systemImage: "checkmark")
                        } else {
                            Text(choice.title)
                        }
                    }
                }
            } label: {
                slot(image: image, contentMode: contentMode, placeholderSymbol: placeholderSymbol, label: label)
                    .overlay(alignment: .bottomLeading) {
                        SourceChoiceBadge(title: choices.first(where: \.isSelected)?.title ?? label)
                    }
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .help("Choose \(label.lowercased())")
            .accessibilityLabel("\(label): \(choices.first(where: \.isSelected)?.title ?? "none")")
            .accessibilityHint("Opens a menu to choose another \(label.lowercased())")
        }
    }

    @ViewBuilder
    private func slot(
        image: CGImage?,
        contentMode: ContentMode,
        placeholderSymbol: String,
        label: String
    ) -> some View {
        Group {
            if let image {
                Rectangle()
                    .fill(.black)
                    .overlay {
                        Image(decorative: image, scale: 1)
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    }
                    .clipped()
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
}

private struct SourceChoiceBadge: View {
    let title: String

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .lineLimit(1)
            Image(systemName: "chevron.up.chevron.down")
                .imageScale(.small)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassEffect(.regular, in: .capsule)
        .padding(6)
        .accessibilityHidden(true)
    }
}

private struct EqualSlotsRow: Layout {
    let spacing: CGFloat
    let slotAspectRatio: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 640
        return CGSize(width: width, height: slotSize(forWidth: width, subviews: subviews).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let size = slotSize(forWidth: bounds.width, subviews: subviews)
        var x = bounds.minX
        for subview in subviews {
            subview.place(at: CGPoint(x: x, y: bounds.minY), proposal: ProposedViewSize(size))
            x += size.width + spacing
        }
    }

    private func slotSize(forWidth width: CGFloat, subviews: Subviews) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let gaps = spacing * CGFloat(subviews.count - 1)
        let slotWidth = max(width - gaps, 0) / CGFloat(subviews.count)
        return CGSize(width: slotWidth, height: slotWidth / slotAspectRatio)
    }
}
