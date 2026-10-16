import AppKit
import SwiftUI
import XCTest
@testable import MacTap

final class PomodoroLiveLayoutTests: XCTestCase {
    func testExpansionPreservesWidthAndControlsHaveComfortableTargets() {
        let compact = PomodoroLiveLayout.size(expanded: false)
        let expanded = PomodoroLiveLayout.size(expanded: true)
        XCTAssertEqual(compact.width, expanded.width)
        XCTAssertGreaterThan(expanded.height, compact.height)
        XCTAssertEqual(PomodoroLiveLayout.controlSize, 36)
        XCTAssertEqual(compact.height, 40 + 2 * PomodoroLiveLayout.inset + 2)
    }
    @MainActor
    func testHostingViewKeepsBoundedSizeAcrossExpandedStateChanges() throws {
        let name = "MacTap.LiveLayoutTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = PomodoroModel(defaults: defaults)
        model.soundEnabled = false
        model.primaryAction()
        let host = NSHostingView(rootView: PomodoroLiveView(model: model))
        host.sizingOptions = []
        for expanded in [false, true, false, true] {
            model.liveExpanded = expanded
            let size = PomodoroLiveLayout.size(expanded: expanded)
            host.setFrameSize(size)
            host.layoutSubtreeIfNeeded()
            XCTAssertEqual(host.frame.size, size)
            XCTAssertLessThanOrEqual(host.frame.height, 252)
            XCTAssertLessThanOrEqual(host.frame.width, 360)
            XCTAssertTrue(host.sizingOptions.isEmpty)
        }
    }
}
