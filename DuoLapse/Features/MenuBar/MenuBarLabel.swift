import AppKit
import DuoLapseCapture
import DuoLapseCore
import SwiftUI

struct MenuBarLabel: View {
    let library: TimelapseLibrary
    let onWidthChange: (CGFloat) -> Void

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: symbolName)
                .font(.system(size: NSFont.systemFontSize))
            if let timerStartDate {
                Text(timerInterval: timerStartDate...Date.distantFuture, countsDown: false)
                    .font(.system(size: NSFont.smallSystemFontSize, weight: .medium).monospacedDigit())
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
