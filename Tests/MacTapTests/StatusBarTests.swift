import AppKit
import XCTest
@testable import MacTap

final class StatusBarTests: XCTestCase {
    func testTimerWidthDoesNotDependOnCountdownOrCompletionText() {
        for text in ["25:00", "09:59", "01:11", "00:00", "180:00", "Feito"] {
            let presentation = StatusBarPresentation(timerText: text, tooltip: "MacTap")
            XCTAssertEqual(presentation.width, 74)
        }
    }

    @MainActor
    func testStatusUpdateRunsInMenuTrackingMode() {
        CFRunLoopAddCommonMode(CFRunLoopGetMain(), CFRunLoopMode(rawValue: RunLoop.Mode.eventTracking.rawValue as CFString))
        var executed = false
        StatusBarController.scheduleForMenuTracking { executed = true }
        let deadline = Date().addingTimeInterval(0.2)
        while !executed && Date() < deadline {
            _ = RunLoop.main.run(mode: .eventTracking, before: deadline)
        }
        XCTAssertTrue(executed, "The status update must not wait for the menu to close")
    }

    func testDisabledLiveReservesOnlyIconWidth() {
        let presentation = StatusBarPresentation(timerText: nil, tooltip: "MacTap · Ativo")
        XCTAssertEqual(presentation.width, 30)
    }

    func testIdenticalPresentationCanSkipRedundantStatusUpdates() {
        let a = StatusBarPresentation(timerText: "25:00", tooltip: "Foco")
        let b = StatusBarPresentation(timerText: "25:00", tooltip: "Foco")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, StatusBarPresentation(timerText: "24:59", tooltip: "Foco"))
    }
}
