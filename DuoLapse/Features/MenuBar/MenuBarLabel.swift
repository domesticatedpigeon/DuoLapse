import AppKit
import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct MenuBarLabel: View {
    static let contentHeight: CGFloat = 16

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
        .frame(height: Self.contentHeight)
        .padding(.horizontal, 4)
        .padding(.top, topInset)
        .fixedSize()
        .frame(height: NSStatusBar.system.thickness, alignment: .top)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            onWidthChange(width)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(timerStartDate == nil ? "DuoLapse" : "DuoLapse recording")
    }

    private var topInset: CGFloat {
        ((NSStatusBar.system.thickness - Self.contentHeight) / 2).rounded(.down)
    }

    private var timerStartDate: Date? {
        library.activeRecorder?.timerStartDate
    }

    private var symbolName: String {
        library.activeRecorder == nil && library.hasRecordingInProgress ? "pause.circle" : "timer"
    }
}
