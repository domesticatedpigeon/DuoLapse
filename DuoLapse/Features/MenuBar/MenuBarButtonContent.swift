import AppKit
import DuoLapseCapture

final class MenuBarButtonContent: NSObject {
    private static let iconSize = NSSize(width: 16, height: 16)
    private static let timeFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)

    private weak var button: NSStatusBarButton?
    private let library: TimelapseLibrary
    private var tickTimer: Timer?
    private var timerStartDate: Date?

    init(button: NSStatusBarButton, library: TimelapseLibrary) {
        self.button = button
        self.library = library
        super.init()
        let icon = NSImage(resource: .menuBarIcon)
        icon.size = Self.iconSize
        icon.isTemplate = true
        button.image = icon
        button.imageHugsTitle = true
        followTimerStartDate()
    }

    func stop() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func followTimerStartDate() {
        let startDate = withObservationTracking {
            library.activeRecorder?.timerStartDate
        } onChange: { [weak self] in
            Task { @MainActor in self?.followTimerStartDate() }
        }
        guard startDate != timerStartDate || tickTimer == nil else { return }
        timerStartDate = startDate
        showElapsedTime()
        scheduleTicks()
    }

    private func scheduleTicks() {
        tickTimer?.invalidate()
        tickTimer = nil
        guard let timerStartDate else { return }
        let elapsed = Date.now.timeIntervalSince(timerStartDate)
        let nextWholeSecond = timerStartDate.addingTimeInterval(elapsed.rounded(.down) + 1)
        let timer = Timer(
            fireAt: nextWholeSecond,
            interval: 1,
            target: self,
            selector: #selector(tick),
            userInfo: nil,
            repeats: true
        )
        timer.tolerance = 0.05
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }

    @objc private func tick() {
        showElapsedTime()
    }

    private func showElapsedTime() {
        guard let button else { return }
        guard let timerStartDate else {
            button.attributedTitle = NSAttributedString()
            button.imagePosition = .imageOnly
            button.setAccessibilityLabel("DuoLapse")
            return
        }
        let elapsed = Duration.seconds(Int(Date.now.timeIntervalSince(timerStartDate)))
        let time = elapsed.formatted(.time(pattern: elapsed < .seconds(3600) ? .minuteSecond : .hourMinuteSecond))
        button.imagePosition = .imageLeading
        button.attributedTitle = NSAttributedString(
            string: "\u{2009}" + time,
            attributes: [.font: Self.timeFont]
        )
        button.setAccessibilityLabel("DuoLapse recording, \(time)")
    }
}
