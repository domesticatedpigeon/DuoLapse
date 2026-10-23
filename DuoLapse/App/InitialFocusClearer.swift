import AppKit
import SwiftUI

struct InitialFocusClearer: NSViewRepresentable {
    func makeNSView(context: Context) -> InitialFocusClearingView {
        InitialFocusClearingView()
    }

    func updateNSView(_ nsView: InitialFocusClearingView, context: Context) {}
}

final class InitialFocusClearingView: NSView {
    private var clearsFocusWhenWindowBecomesKey = true

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: window
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose),
            name: NSWindow.willCloseNotification,
            object: window
        )
        if window.isKeyWindow {
            windowDidBecomeKey()
        }
    }

    @objc private func windowDidBecomeKey() {
        guard clearsFocusWhenWindowBecomesKey else { return }
        clearsFocusWhenWindowBecomesKey = false
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(nil)
        }
    }

    @objc private func windowWillClose() {
        clearsFocusWhenWindowBecomesKey = true
    }
}
