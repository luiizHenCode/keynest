import Foundation

/// Validated values are immutable; construct a new configuration to change settings.
struct PomodoroConfiguration: Equatable, Sendable {
    let focusMinutes: Int
    let restMinutes: Int
    let cycleLimit: Int?
    let autoAdvance: Bool

    init(
        focusMinutes: Int = 25,
        restMinutes: Int = 5,
        cycleLimit: Int? = nil,
        autoAdvance: Bool = false
    ) {
        self.focusMinutes = min(max(focusMinutes, 1), 180)
        self.restMinutes = min(max(restMinutes, 1), 60)
        self.cycleLimit = cycleLimit.map { min(max($0, 1), 99) }
        self.autoAdvance = autoAdvance
    }

    var focusDuration: TimeInterval { TimeInterval(focusMinutes) * 60 }
    var restDuration: TimeInterval { TimeInterval(restMinutes) * 60 }
    var cycleDuration: TimeInterval { focusDuration + restDuration }
    var totalPlannedDuration: TimeInterval? {
        cycleLimit.map { TimeInterval($0) * cycleDuration }
    }
    var totalPlannedFocusDuration: TimeInterval? {
        cycleLimit.map { TimeInterval($0) * focusDuration }
    }
}

/// A clock-independent value type. The caller supplies dates and handles returned events.
struct PomodoroSession: Equatable, Sendable {
    enum Phase: Equatable, Sendable { case focus, rest }
    enum State: Equatable, Sendable { case idle, running, paused, waiting, completed }
    enum Event: Equatable, Sendable { case focusFinished, restFinished, completed }

    let configuration: PomodoroConfiguration
    private(set) var phase: Phase = .focus
    private(set) var state: State = .idle
    private(set) var completedCycles: Int = 0
    /// Present only while running, including when the caller has not yet processed a deadline.
    private(set) var phaseEndDate: Date?
    private var frozenRemaining: TimeInterval

    init(configuration: PomodoroConfiguration = PomodoroConfiguration()) {
        self.configuration = configuration
        self.frozenRemaining = configuration.focusDuration
    }

    var totalPlannedDuration: TimeInterval? { configuration.totalPlannedDuration }
    var totalPlannedFocusDuration: TimeInterval? { configuration.totalPlannedFocusDuration }

    /// Starts an idle session or the full next phase in manual mode. Otherwise a no-op.
    mutating func start(at date: Date) {
        guard state == .idle || state == .waiting else { return }
        state = .running
        phaseEndDate = date.addingTimeInterval(frozenRemaining)
    }

    /// Reconciles elapsed time before pausing; callers must handle these events like tick events.
    @discardableResult
    mutating func pause(at date: Date) -> [Event] {
        guard state == .running else { return [] }
        let events = tick(at: date)
        if state == .running {
            frozenRemaining = remaining(at: date)
            phaseEndDate = nil
            state = .paused
        }
        return events
    }

    mutating func resume(at date: Date) {
        guard state == .paused else { return }
        state = .running
        phaseEndDate = date.addingTimeInterval(frozenRemaining)
    }

    /// Skipping a rest counts the cycle and starts the next focus immediately.
    /// Does not emit restFinished: no rest timer expired.
    @discardableResult
    mutating func skipRest(at date: Date) -> [Event] {
        guard phase == .rest, state == .running || state == .paused || state == .waiting else { return [] }
        completedCycles = min(completedCycles, Int.max - 1) + 1
        if completedCycles == configuration.cycleLimit {
            finish()
            return [.completed]
        }
        phase = .focus
        frozenRemaining = configuration.focusDuration
        state = .waiting
        phaseEndDate = nil
        start(at: date)
        return []
    }

    mutating func reset() {
        self = PomodoroSession(configuration: configuration)
    }

    /// Does not advance the state. Idle/waiting return a full phase; paused returns frozen time.
    func remaining(at date: Date) -> TimeInterval {
        guard let deadline = phaseEndDate else { return frozenRemaining }
        return max(0, deadline.timeIntervalSince(date))
    }

    /// Includes the final rest. Manual, unlimited, idle, paused and completed sessions return nil.
    /// This is a projection assuming no future pauses, even if a tick is overdue.
    func estimatedFinish(at _: Date) -> Date? {
        guard state == .running, configuration.autoAdvance,
              let limit = configuration.cycleLimit, let deadline = phaseEndDate else { return nil }
        let laterCycles = TimeInterval(limit - completedCycles - 1) * configuration.cycleDuration
        let currentRest = phase == .focus ? configuration.restDuration : 0
        return deadline.addingTimeInterval(currentRest + laterCycles)
    }

    /// Auto recovery is O(1), with no replay of historical alerts: only the most recent
    /// phase boundary is emitted, followed by completed when appropriate (at most two events).
    /// Manual recovery processes exactly one boundary and waits for an explicit start.
    @discardableResult
    mutating func tick(at date: Date) -> [Event] {
        guard state == .running, let deadline = phaseEndDate, date >= deadline else { return [] }
        if !configuration.autoAdvance {
            if phase == .focus {
                phase = .rest
                frozenRemaining = configuration.restDuration
                phaseEndDate = nil
                state = .waiting
                return [.focusFinished]
            }
            completedCycles += 1
            if completedCycles == configuration.cycleLimit {
                finish()
                return [.restFinished, .completed]
            }
            phase = .focus
            frozenRemaining = configuration.focusDuration
            phaseEndDate = nil
            state = .waiting
            return [.restFinished]
        }

        // Anchor the current cycle to its original deadline, never to the late tick.
        let cycleDuration = configuration.cycleDuration
        let cycleStart = deadline.addingTimeInterval(
            -(phase == .focus ? configuration.focusDuration : cycleDuration)
        )
        let elapsed = date.timeIntervalSince(cycleStart)
        if let limit = configuration.cycleLimit,
           elapsed >= TimeInterval(limit - completedCycles) * cycleDuration {
            completedCycles = limit
            finish()
            return [.restFinished, .completed]
        }

        let skippedCycles = (elapsed / cycleDuration).rounded(.down)
        // Saturation keeps even extreme unlimited sessions representable as an Int.
        if skippedCycles >= Double(Int.max - completedCycles) {
            completedCycles = Int.max
        } else {
            completedCycles += Int(skippedCycles)
        }
        let position = elapsed.truncatingRemainder(dividingBy: cycleDuration)
        if position < configuration.focusDuration {
            phase = .focus
            frozenRemaining = configuration.focusDuration - position
        } else {
            phase = .rest
            frozenRemaining = cycleDuration - position
        }
        phaseEndDate = date.addingTimeInterval(frozenRemaining)
        return [phase == .focus ? .restFinished : .focusFinished]
    }

    private mutating func finish() {
        phase = .rest
        state = .completed
        phaseEndDate = nil
        frozenRemaining = 0
    }
}
