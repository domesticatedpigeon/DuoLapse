import AppKit
import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct MenuBarLabel: View {
    let library: TimelapseLibrary
    let onWidthChange: (CGFloat) -> Void
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbolName)
            if let elapsedSeconds {
                Text(RecordingTimeFormat.compact(seconds: Double(elapsedSeconds)))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(elapsedSeconds)))
                    .animation(reducesMotion ? nil : .snappy, value: elapsedSeconds)
            }
        }
        .font(Font(NSFont.menuBarFont(ofSize: 0)))
        .padding(.horizontal, 6)
        .fixedSize()
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
