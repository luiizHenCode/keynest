import Foundation
import XCTest
@testable import MacTap

final class PomodoroSessionTests: XCTestCase {
    private let origin = Date(timeIntervalSince1970: 1_700_000_000)

    private func date(_ seconds: TimeInterval) -> Date {
        origin.addingTimeInterval(seconds)
    }

    private func session(auto: Bool = true, limit: Int? = nil) -> PomodoroSession {
        PomodoroSession(configuration: PomodoroConfiguration(
            focusMinutes: 1, restMinutes: 2, cycleLimit: limit, autoAdvance: auto
        ))
    }

    func testConfigurationClampsBeforeConvertingOrMultiplying() {
        let low = PomodoroConfiguration(focusMinutes: .min, restMinutes: .min, cycleLimit: .min)
        XCTAssertEqual(low.focusMinutes, 1)
        XCTAssertEqual(low.restMinutes, 1)
        XCTAssertEqual(low.cycleLimit, 1)
        XCTAssertFalse(low.autoAdvance)
        let high = PomodoroConfiguration(focusMinutes: .max, restMinutes: .max, cycleLimit: .max)
        XCTAssertEqual(high.focusMinutes, 180)
        XCTAssertEqual(high.restMinutes, 60)
        XCTAssertEqual(high.cycleLimit, 99)
        XCTAssertEqual(high.totalPlannedDuration, 1_425_600)
        XCTAssertEqual(high.totalPlannedFocusDuration, 1_069_200)
        XCTAssertTrue(high.totalPlannedDuration!.isFinite)
        XCTAssertNil(PomodoroConfiguration().totalPlannedDuration)
        XCTAssertNil(PomodoroConfiguration().totalPlannedFocusDuration)
    }

    func testIdleAndDefaultConfiguration() {
        let sut = PomodoroSession()
        XCTAssertEqual(sut.configuration, PomodoroConfiguration())
        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.phase, .focus)
        XCTAssertEqual(sut.completedCycles, 0)
        XCTAssertEqual(sut.remaining(at: origin), 25 * 60)
        XCTAssertNil(sut.phaseEndDate)
        XCTAssertNil(sut.estimatedFinish(at: origin))
    }

    func testFocusToRestAndExactDeadlineBoundary() {
        var sut = session()
        sut.start(at: origin)
        XCTAssertEqual(sut.phaseEndDate, date(60))
        XCTAssertEqual(sut.remaining(at: date(59.5)), 0.5)
        XCTAssertEqual(sut.tick(at: date(59.5)), [])
        XCTAssertEqual(sut.tick(at: date(60)), [.focusFinished])
        XCTAssertEqual(sut.phase, .rest)
        XCTAssertEqual(sut.state, .running)
        XCTAssertEqual(sut.completedCycles, 0)
        XCTAssertEqual(sut.remaining(at: date(60)), 120)
        XCTAssertEqual(sut.phaseEndDate, date(180))
        XCTAssertEqual(sut.tick(at: date(60)), [])
    }

    func testRestToNextFocusCountsCycleOnlyAfterRest() {
        var sut = session()
        sut.start(at: origin)
        XCTAssertEqual(sut.tick(at: date(60)), [.focusFinished])
        XCTAssertEqual(sut.tick(at: date(180)), [.restFinished])
        XCTAssertEqual(sut.completedCycles, 1)
        XCTAssertEqual(sut.phase, .focus)
        XCTAssertEqual(sut.phaseEndDate, date(240))
        XCTAssertEqual(sut.remaining(at: date(180)), 60)
    }

    func testFiniteSessionIncludesFinalRest() {
        var sut = session(limit: 1)
        XCTAssertEqual(sut.totalPlannedDuration, 180)
        XCTAssertEqual(sut.totalPlannedFocusDuration, 60)
        sut.start(at: origin)
        XCTAssertEqual(sut.estimatedFinish(at: origin), date(180))
        XCTAssertEqual(sut.tick(at: date(60)), [.focusFinished])
        XCTAssertEqual(sut.state, .running)
        XCTAssertEqual(sut.completedCycles, 0)
        XCTAssertEqual(sut.tick(at: date(179)), [])
        XCTAssertEqual(sut.tick(at: date(180)), [.restFinished, .completed])
        XCTAssertEqual(sut.state, .completed)
        XCTAssertEqual(sut.phase, .rest)
        XCTAssertEqual(sut.completedCycles, 1)
        XCTAssertEqual(sut.remaining(at: date(200)), 0)
        XCTAssertNil(sut.phaseEndDate)
        XCTAssertNil(sut.estimatedFinish(at: date(200)))
        XCTAssertEqual(sut.tick(at: date(1e12)), [])
        sut.start(at: date(200))
        sut.resume(at: date(200))
        XCTAssertEqual(sut.state, .completed)
    }

    func testUnlimitedContinuesAndHasNoEstimate() {
        var sut = session()
        sut.start(at: origin)
        XCTAssertNil(sut.totalPlannedDuration)
        XCTAssertNil(sut.estimatedFinish(at: origin))
        XCTAssertEqual(sut.tick(at: date(180 * 100)), [.restFinished])
        XCTAssertEqual(sut.completedCycles, 100)
        XCTAssertEqual(sut.state, .running)
        XCTAssertEqual(sut.phase, .focus)
    }

    func testManualWaitsWithFullNextPhaseEvenAfterLongDelay() {
        var sut = session(auto: false, limit: 2)
        sut.start(at: origin)
        XCTAssertNil(sut.estimatedFinish(at: origin))
        XCTAssertEqual(sut.tick(at: date(1e12)), [.focusFinished])
        XCTAssertEqual(sut.state, .waiting)
        XCTAssertEqual(sut.phase, .rest)
        XCTAssertEqual(sut.completedCycles, 0)
        XCTAssertNil(sut.phaseEndDate)
        XCTAssertEqual(sut.remaining(at: date(2e12)), 120)
        XCTAssertEqual(sut.tick(at: date(2e12)), [])
        sut.resume(at: date(500))
        XCTAssertEqual(sut.state, .waiting)
        sut.start(at: date(500))
        XCTAssertEqual(sut.phaseEndDate, date(620))
        XCTAssertEqual(sut.tick(at: date(900)), [.restFinished])
        XCTAssertEqual(sut.completedCycles, 1)
        XCTAssertEqual(sut.phase, .focus)
        XCTAssertEqual(sut.state, .waiting)
        XCTAssertEqual(sut.remaining(at: date(1000)), 60)
    }

    func testManualFiniteCompletesOnlyAfterExplicitFinalRest() {
        var sut = session(auto: false, limit: 1)
        sut.start(at: origin)
        XCTAssertEqual(sut.tick(at: date(600)), [.focusFinished])
        XCTAssertEqual(sut.completedCycles, 0)
        sut.start(at: date(1000))
        XCTAssertEqual(sut.tick(at: date(1120)), [.restFinished, .completed])
        XCTAssertEqual(sut.completedCycles, 1)
        XCTAssertEqual(sut.state, .completed)
    }

    func testPauseFreezesRemainingAndResumeMovesDeadlinesAndEstimate() {
        var sut = session(limit: 2)
        sut.start(at: origin)
        XCTAssertEqual(sut.estimatedFinish(at: origin), date(360))
        XCTAssertEqual(sut.pause(at: date(20)), [])
        XCTAssertEqual(sut.state, .paused)
        XCTAssertNil(sut.phaseEndDate)
        XCTAssertNil(sut.estimatedFinish(at: date(20)))
        XCTAssertEqual(sut.remaining(at: date(1000)), 40)
        XCTAssertEqual(sut.tick(at: date(1000)), [])
        sut.start(at: date(1000))
        XCTAssertEqual(sut.state, .paused)
        sut.resume(at: date(1000))
        XCTAssertEqual(sut.phaseEndDate, date(1040))
        XCTAssertEqual(sut.estimatedFinish(at: date(1000)), date(1340))
        XCTAssertEqual(sut.tick(at: date(1040)), [.focusFinished])
        XCTAssertEqual(sut.pause(at: date(1060)), [])
        XCTAssertEqual(sut.remaining(at: date(5000)), 100)
        sut.resume(at: date(5000))
        XCTAssertEqual(sut.phaseEndDate, date(5100))
    }

    func testPauseReconcilesBoundaryAndReturnsEvents() {
        var automatic = session()
        automatic.start(at: origin)
        XCTAssertEqual(automatic.pause(at: date(60)), [.focusFinished])
        XCTAssertEqual(automatic.state, .paused)
        XCTAssertEqual(automatic.phase, .rest)
        XCTAssertEqual(automatic.remaining(at: date(500)), 120)
        var manual = session(auto: false)
        manual.start(at: origin)
        XCTAssertEqual(manual.pause(at: date(60)), [.focusFinished])
        XCTAssertEqual(manual.state, .waiting)
        var finite = session(limit: 1)
        finite.start(at: origin)
        XCTAssertEqual(finite.pause(at: date(180)), [.restFinished, .completed])
        XCTAssertEqual(finite.state, .completed)
    }

    func testLateTicksKeepOriginalTimelineAndCoalesceEvents() {
        var sut = session(limit: 10)
        sut.start(at: origin)
        XCTAssertEqual(sut.tick(at: date(95)), [.focusFinished])
        XCTAssertEqual(sut.phaseEndDate, date(180))
        XCTAssertEqual(sut.remaining(at: date(95)), 85)
        XCTAssertEqual(sut.tick(at: date(570)), [.restFinished])
        XCTAssertEqual(sut.completedCycles, 3)
        XCTAssertEqual(sut.phase, .focus)
        XCTAssertEqual(sut.phaseEndDate, date(600))
        XCTAssertEqual(sut.estimatedFinish(at: date(570)), date(1800))
        XCTAssertEqual(sut.tick(at: date(790)), [.focusFinished])
        XCTAssertEqual(sut.completedCycles, 4)
        XCTAssertEqual(sut.phase, .rest)
        XCTAssertEqual(sut.phaseEndDate, date(900))
        XCTAssertEqual(sut.tick(at: date(1e12)), [.restFinished, .completed])
        XCTAssertEqual(sut.completedCycles, 10)
    }

    func testTrillionSecondRecoveryUsesArithmeticWithoutAlertStorm() {
        var sut = session()
        sut.start(at: origin)
        let elapsed: TimeInterval = 1e12
        XCTAssertEqual(sut.tick(at: date(elapsed)), [.focusFinished])
        XCTAssertEqual(sut.completedCycles, 5_555_555_555)
        XCTAssertEqual(sut.phase, .rest)
        XCTAssertEqual(sut.remaining(at: date(elapsed)), 80)
        XCTAssertEqual(sut.phaseEndDate, date(elapsed + 80))
        XCTAssertEqual(sut.tick(at: date(elapsed)), [])
        XCTAssertEqual(sut.tick(at: date(elapsed + 80)), [.restFinished])
        XCTAssertEqual(sut.completedCycles, 5_555_555_556)
    }

    func testResetPreservesSnapshotAndValueCopiesAreIndependent() {
        var sut = session(limit: 2)
        let original = sut
        sut.start(at: origin)
        _ = sut.tick(at: date(180))
        XCTAssertEqual(original.state, .idle)
        XCTAssertEqual(original.completedCycles, 0)
        sut.reset()
        XCTAssertEqual(sut, original)
        sut.resume(at: origin)
        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(sut.pause(at: origin), [])
    }

    func testSkipWaitingRestStartsNextFocusAndCountsCycle() {
        var sut = session(auto: false, limit: 2)
        sut.start(at: origin)
        _ = sut.tick(at: date(60))
        XCTAssertEqual(sut.state, .waiting)
        XCTAssertEqual(sut.skipRest(at: date(70)), [])
        XCTAssertEqual(sut.phase, .focus)
        XCTAssertEqual(sut.state, .running)
        XCTAssertEqual(sut.completedCycles, 1)
        XCTAssertEqual(sut.phaseEndDate, date(130))
    }

    func testSkipFinalRestCompletesWithoutExtraFocus() {
        var sut = session(auto: false, limit: 1)
        sut.start(at: origin)
        _ = sut.tick(at: date(60))
        XCTAssertEqual(sut.skipRest(at: date(70)), [.completed])
        XCTAssertEqual(sut.state, .completed)
        XCTAssertEqual(sut.completedCycles, 1)
        XCTAssertNil(sut.phaseEndDate)
        XCTAssertEqual(sut.skipRest(at: date(80)), [])
    }

    func testSkipRunningAndPausedRestAndIgnoreFocus() {
        for paused in [true, false] {
            var sut = session(limit: 2)
            sut.start(at: origin)
            XCTAssertEqual(sut.skipRest(at: date(10)), [])
            XCTAssertEqual(sut.phaseEndDate, date(60))
            _ = sut.tick(at: date(60))
            if paused { _ = sut.pause(at: date(70)) }
            XCTAssertEqual(sut.skipRest(at: date(80)), [])
            XCTAssertEqual(sut.completedCycles, 1)
            XCTAssertEqual(sut.phase, .focus)
            XCTAssertEqual(sut.state, .running)
            XCTAssertEqual(sut.phaseEndDate, date(140))
            XCTAssertEqual(sut.estimatedFinish(at: date(80)), date(260))
        }
    }

    func testRepeatedStartAndResumeDoNotMoveRunningDeadline() {
        var sut = session()
        sut.start(at: origin)
        sut.start(at: date(20))
        sut.resume(at: date(30))
        XCTAssertEqual(sut.phaseEndDate, date(60))
        XCTAssertEqual(sut.remaining(at: date(100)), 0)
        XCTAssertEqual(sut.phase, .focus) // Queries never mutate/reconcile the session.
    }
}
