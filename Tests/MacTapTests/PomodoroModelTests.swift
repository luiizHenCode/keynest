import XCTest
@testable import MacTap

final class PomodoroModelTests: XCTestCase {
    @MainActor
    func testLiveStylesAreExclusiveAndPersistWithoutRestartingTimer() throws {
        let name = "MacTap.PomodoroTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = PomodoroModel(defaults: defaults)
        model.soundEnabled = false
        XCTAssertEqual(model.liveStyle, .floating)
        XCTAssertTrue(model.livePinned)
        model.livePinned = false
        XCTAssertFalse(model.menuBarLiveVisible)
        model.primaryAction()
        let deadline = model.session.phaseEndDate
        XCTAssertTrue(model.floatingLiveVisible)
        model.liveStyle = .menuBar
        XCTAssertFalse(model.floatingLiveVisible)
        XCTAssertTrue(model.menuBarLiveVisible)
        XCTAssertEqual(model.session.phaseEndDate, deadline)
        XCTAssertEqual(model.liveStatusSymbol, "timer")
        let restored = PomodoroModel(defaults: defaults)
        XCTAssertEqual(restored.liveStyle, .menuBar)
        XCTAssertFalse(restored.livePinned)
        model.liveEnabled = false
        XCTAssertFalse(model.menuBarLiveVisible)
        XCTAssertFalse(model.floatingLiveVisible)
        XCTAssertEqual(model.session.state, .running)
    }

    @MainActor
    func testConfigurationPersistenceAndSessionControls() throws {
        let name = "MacTap.PomodoroTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = PomodoroModel(defaults: defaults)
        XCTAssertEqual(model.configuration.focusMinutes, 25)
        XCTAssertEqual(model.configuration.restMinutes, 5)
        XCTAssertEqual(model.configuration.cycleLimit, 4)
        model.soundEnabled = false
        model.focusMinutes = 10
        model.restMinutes = 2
        model.cycleCount = 3
        model.autoAdvance = true
        XCTAssertEqual(model.countdown, "10:00")
        XCTAssertEqual(model.configuration.totalPlannedDuration, 2160)
        model.primaryAction()
        XCTAssertEqual(model.session.state, .running)
        XCTAssertFalse(model.canConfigure)
        XCTAssertNotNil(model.session.phaseEndDate)
        XCTAssertNotNil(model.session.estimatedFinish(at: model.now))
        model.primaryAction()
        XCTAssertEqual(model.session.state, .paused)
        XCTAssertNil(model.session.phaseEndDate)
        model.primaryAction()
        XCTAssertEqual(model.session.state, .running)
        model.reset()
        XCTAssertEqual(model.session.state, .idle)
        XCTAssertEqual(model.countdown, "10:00")
        let restored = PomodoroModel(defaults: defaults)
        XCTAssertEqual(restored.configuration, model.configuration)
        XCTAssertEqual(restored.session.state, .idle)
        XCTAssertFalse(restored.soundEnabled)
    }

    @MainActor
    func testLiveExpandsSilentlyAndSkipFinalRestCompletes() throws {
        let name = "MacTap.PomodoroTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = PomodoroModel(defaults: defaults)
        model.soundEnabled = false
        model.focusMinutes = 1
        model.restMinutes = 1
        model.cycleCount = 1
        XCTAssertTrue(model.liveEnabled)
        XCTAssertFalse(model.liveVisible)
        model.primaryAction()
        XCTAssertTrue(model.liveVisible)
        XCTAssertFalse(model.liveExpanded)
        model.tick(at: try XCTUnwrap(model.session.phaseEndDate))
        XCTAssertTrue(model.liveExpanded)
        XCTAssertTrue(model.canSkipRest)
        XCTAssertEqual(model.session.state, .waiting)
        model.skipRest()
        XCTAssertEqual(model.session.state, .completed)
        XCTAssertTrue(model.liveExpanded)
        XCTAssertFalse(model.canSkipRest)
        model.liveEnabled = false
        XCTAssertFalse(model.liveVisible)
        let restored = PomodoroModel(defaults: defaults)
        XCTAssertFalse(restored.liveEnabled)
        model.reset()
        XCTAssertFalse(model.liveExpanded)
    }

    @MainActor
    func testLiveContinueDoesNotPauseAutomaticPhaseAndManualStartsNextPhase() throws {
        let name = "MacTap.PomodoroTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let model = PomodoroModel(defaults: defaults)
        model.soundEnabled = false
        model.focusMinutes = 1
        model.autoAdvance = true
        model.primaryAction()
        model.tick(at: try XCTUnwrap(model.session.phaseEndDate))
        XCTAssertTrue(model.liveExpanded)
        XCTAssertEqual(model.session.phase, .rest)
        let deadline = model.session.phaseEndDate
        model.continueFromLive()
        XCTAssertEqual(model.session.state, .running)
        XCTAssertEqual(model.session.phaseEndDate, deadline)
        XCTAssertFalse(model.liveExpanded)
        model.reset()
        model.autoAdvance = false
        model.primaryAction()
        model.tick(at: try XCTUnwrap(model.session.phaseEndDate))
        XCTAssertEqual(model.session.state, .waiting)
        model.continueFromLive()
        XCTAssertEqual(model.session.state, .running)
        XCTAssertEqual(model.session.phase, .rest)
        XCTAssertFalse(model.liveExpanded)
    }

    @MainActor
    func testUnlimitedHasNoTotalAndSavedDurationsAreClamped() throws {
        let name = "MacTap.PomodoroTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(Int.max, forKey: "pomodoro.focus")
        defaults.set(-4, forKey: "pomodoro.rest")
        defaults.set(1000, forKey: "pomodoro.cycles")
        let model = PomodoroModel(defaults: defaults)
        XCTAssertEqual(model.focusMinutes, 180)
        XCTAssertEqual(model.restMinutes, 1)
        XCTAssertEqual(model.cycleCount, 99)
        model.unlimited = true
        XCTAssertNil(model.configuration.totalPlannedDuration)
        XCTAssertEqual(PomodoroModel.duration(7200), "2h 0min")
        XCTAssertEqual(PomodoroModel.duration(1500), "25 min")
    }
}
