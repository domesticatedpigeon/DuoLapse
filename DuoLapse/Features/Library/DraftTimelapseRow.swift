import SwiftUI

struct DraftTimelapseRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SourcesPreview(screenImage: nil, cameraImage: nil, style: .compact)
                .frame(width: 96)

            VStack(alignment: .leading, spacing: 2) {
                Text("New Timelapse")
                    .lineLimit(1)
                Label("Not started", systemImage: "circle.dashed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
