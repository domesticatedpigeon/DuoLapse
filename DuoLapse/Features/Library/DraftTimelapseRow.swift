import SwiftUI

struct DraftTimelapseRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SourcesPreview(screenImage: nil, cameraImage: nil, style: .compact)
                .frame(width: 96)

            VStack(alignment: .leading, spacing: 2) {
                Text("New Timelapse")
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "circle.dashed")
                        .accessibilityHidden(true)
                    Text("Not started")
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
