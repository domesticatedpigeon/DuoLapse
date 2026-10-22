import AppKit
import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct MenuBarLabel: View {
    let library: TimelapseLibrary
    let onWidthChange: (CGFloat) -> Void
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: symbolName)
                .font(.system(size: NSFont.systemFontSize))
            if let elapsedSeconds {
                RollingDigits(
                    text: RecordingTimeFormat.compact(seconds: Double(elapsedSeconds)),
                    animation: reducesMotion ? nil : .smooth(duration: 0.35)
                )
                .font(.system(size: NSFont.smallSystemFontSize, weight: .medium).monospacedDigit())
            }
        }
        .padding(.horizontal, 4)
        .fixedSize()
        .frame(height: NSStatusBar.system.thickness)
        .clipped()
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            onWidthChange(width)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var elapsedSeconds: Int? {
        guard let active = library.activeRecorder else { return nil }
        _ = library.heartbeat
        return Int(active.recordedDuration.components.seconds)
    }

    private var symbolName: String {
        library.activeRecorder == nil && library.hasRecordingInProgress ? "pause.circle" : "timer"
    }

    private var accessibilityDescription: String {
        guard let elapsedSeconds else { return "DuoLapse" }
        return "DuoLapse recording, \(RecordingTimeFormat.compact(seconds: Double(elapsedSeconds)))"
    }
}

private struct RollingDigits: View {
    let text: String
    let animation: Animation?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(slotsFromTrailingEdge, id: \.slot) { entry in
                ZStack {
                    Text(String(entry.character))
                        .id(entry.character)
                        .transition(.push(from: .top))
                }
                .clipped()
                .animation(animation, value: entry.character)
            }
        }
    }

    private var slotsFromTrailingEdge: [(slot: Int, character: Character)] {
        text.enumerated().map { (slot: text.count - $0.offset, character: $0.element) }
    }
}
