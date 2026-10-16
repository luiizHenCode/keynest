import AppKit
import XCTest
@testable import MacTap

final class KeyboardMonitorTests: XCTestCase {
    func testLocalTypingDoesNotRequireStartingGlobalMonitor() throws {
        let monitor = KeyboardMonitor()
        var count = 0
        monitor.onLocalKeyDown = { count += 1 }
        let event = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero,
                                                  modifierFlags: [], timestamp: 0,
                                                  windowNumber: 0, context: nil,
                                                  characters: "a", charactersIgnoringModifiers: "a",
                                                  isARepeat: false, keyCode: 0))
        monitor.handleLocalEvent(event)
        XCTAssertEqual(count, 1)
        XCTAssertFalse(monitor.isRunning)
    }

    func testLocalAutoRepeatDoesNotPlayAgain() throws {
        let monitor = KeyboardMonitor()
        var count = 0
        monitor.onLocalKeyDown = { count += 1 }
        let event = try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero,
                                                  modifierFlags: [], timestamp: 0,
                                                  windowNumber: 0, context: nil,
                                                  characters: "a", charactersIgnoringModifiers: "a",
                                                  isARepeat: true, keyCode: 0))
        monitor.handleLocalEvent(event)
        XCTAssertEqual(count, 0)
    }
}
