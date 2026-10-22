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
            if let timerStartDate {
                TimelineView(.periodic(from: timerStartDate, by: 1)) { context in
                    let elapsed = Duration.seconds(Int(context.date.timeIntervalSince(timerStartDate)))
                    Text(
                        elapsed.formatted(.time(pattern: elapsed < .seconds(3600) ? .minuteSecond : .hourMinuteSecond))
                    )
                    .font(.system(size: NSFont.smallSystemFontSize, weight: .medium).monospacedDigit())
                    .contentTransition(.numericText(countsDown: true))
                    .animation(reducesMotion ? nil : .smooth, value: elapsed)
                }
            }
        }
        .padding(.horizontal, 4)
        .fixedSize()
        .frame(height: NSStatusBar.system.thickness)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            onWidthChange(width)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(timerStartDate == nil ? "DuoLapse" : "DuoLapse recording")
    }

    private var timerStartDate: Date? {
        library.activeRecorder?.timerStartDate
    }

    private var symbolName: String {
        library.activeRecorder == nil && library.hasRecordingInProgress ? "pause.circle" : "timer"
    }
}
