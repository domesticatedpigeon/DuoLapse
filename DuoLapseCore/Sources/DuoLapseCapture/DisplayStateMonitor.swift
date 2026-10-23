import AppKit

final class DisplayStateMonitor {
    static let shared = DisplayStateMonitor()

    private(set) var systemWakeCount = 0
    private var areDisplaysAsleep = false
    private var isScreenLocked = false
    private var isSystemAsleep = false
    private var observers: [(NotificationCenter, any NSObjectProtocol)] = []

    var isScreenAvailable: Bool {
        !areDisplaysAsleep && !isScreenLocked && !isSystemAsleep
    }

    private init() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        observe(workspaceCenter, NSWorkspace.screensDidSleepNotification) { $0.areDisplaysAsleep = true }
        observe(workspaceCenter, NSWorkspace.screensDidWakeNotification) { monitor in
            monitor.areDisplaysAsleep = false
            ScreenFrameSource.forgetDisplays()
        }
        observe(NotificationCenter.default, NSApplication.didChangeScreenParametersNotification) { _ in
            ScreenFrameSource.forgetDisplays()
        }
        observe(workspaceCenter, NSWorkspace.willSleepNotification) { $0.isSystemAsleep = true }
        observe(workspaceCenter, NSWorkspace.didWakeNotification) { monitor in
            monitor.isSystemAsleep = false
            monitor.systemWakeCount += 1
        }
        let distributedCenter = DistributedNotificationCenter.default()
        observe(distributedCenter, Notification.Name("com.apple.screenIsLocked")) { $0.isScreenLocked = true }
        observe(distributedCenter, Notification.Name("com.apple.screenIsUnlocked")) { $0.isScreenLocked = false }
    }

    private func observe(
        _ center: NotificationCenter,
        _ name: Notification.Name,
        update: @escaping @MainActor (DisplayStateMonitor) -> Void
    ) {
        let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                update(self)
            }
        }
        observers.append((center, observer))
    }
}
