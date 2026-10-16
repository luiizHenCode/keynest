import AppKit
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let pomodoroLive = PomodoroLiveController()
    let statusBar = StatusBarController()
    func applicationWillTerminate(_ notification: Notification) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["mactap.pomodoro.phase"])
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

/// Observe the actual settings window without replacing SwiftUI's window delegate.
struct MainWindowLifecycle: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowLifecycleView {
        WindowLifecycleView(frame: .zero)
    }

    func updateNSView(_ nsView: WindowLifecycleView, context: Context) {}
}

final class WindowLifecycleView: NSView {
    private var closeObserver: NSObjectProtocol?
    private weak var observedWindow: NSWindow?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard observedWindow !== window else { return }
        if let closeObserver {
            NotificationCenter.default.removeObserver(closeObserver)
            self.closeObserver = nil
        }
        observedWindow = window
        guard let window else { return }
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(srgbRed: 0.065, green: 0.075, blue: 0.085, alpha: 1)
        NSApplication.shared.setActivationPolicy(.regular)
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            // Accessory apps keep their status item and audio, but leave the Dock and Cmd-Tab.
            NSApplication.shared.setActivationPolicy(.accessory)
        }
    }

    deinit {
        if let closeObserver { NotificationCenter.default.removeObserver(closeObserver) }
    }
}
