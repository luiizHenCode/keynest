import AppKit
import CoreGraphics

/// The listen-only tap never modifies events or reads their text/key codes.
final class KeyboardMonitor {
    var onKeyDown: (() -> Void)?
    var onLocalKeyDown: (() -> Void)?
    private var localMonitor: Any?

    func startLocal() {
        guard localMonitor == nil else { return }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleLocalEvent(event)
            return event
        }
    }

    func handleLocalEvent(_ event: NSEvent) {
        guard event.type == .keyDown, !event.isARepeat else { return }
        onLocalKeyDown?()
    }

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    var hasPermission: Bool { CGPreflightListenEventAccess() }
    var isRunning: Bool {
        guard let tap else { return false }
        return CFMachPortIsValid(tap) && CGEvent.tapIsEnabled(tap: tap)
    }

    func requestPermission() {
        CGRequestListenEventAccess()
    }

    @discardableResult
    func start() -> Bool {
        if isRunning { return true }
        stop()
        guard hasPermission else { return false }
        let callback: CGEventTapCallBack = { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(context).takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = monitor.tap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
            } else if type == .keyDown,
                      event.getIntegerValueField(.keyboardEventAutorepeat) == 0,
                      event.getIntegerValueField(.eventTargetUnixProcessID) != Int64(ProcessInfo.processInfo.processIdentifier) {
                monitor.onKeyDown?()
            }
            return Unmanaged.passUnretained(event)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            return false
        }
        self.tap = tap
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        tap = nil
        source = nil
    }

    deinit {
        stop()
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
    }
}
