import AppKit
import Combine
import UserNotifications

enum PomodoroLiveStyle: String, CaseIterable, Identifiable {
    case floating
    case menuBar

    var id: String { rawValue }
    var title: String { self == .floating ? L10n.tr("Flutuante") : L10n.tr("Barra de menus") }
    var symbol: String { self == .floating ? "rectangle.on.rectangle" : "menubar.rectangle" }
}

@MainActor
final class PomodoroModel: ObservableObject {
    @Published var focusMinutes: Int { didSet { saveSettings() } }
    @Published var restMinutes: Int { didSet { saveSettings() } }
    @Published var unlimited: Bool { didSet { saveSettings() } }
    @Published var cycleCount: Int { didSet { saveSettings() } }
    @Published var autoAdvance: Bool { didSet { saveSettings() } }
    @Published var soundEnabled: Bool { didSet { saveSettings() } }
    @Published var notificationsEnabled: Bool { didSet { saveSettings() } }
    @Published var liveEnabled: Bool { didSet { defaults.set(liveEnabled, forKey: "pomodoro.live") } }
    @Published var liveStyle: PomodoroLiveStyle {
        didSet { defaults.set(liveStyle.rawValue, forKey: "pomodoro.liveStyle") }
    }
    @Published var livePinned: Bool {
        didSet { defaults.set(livePinned, forKey: "pomodoro.livePinned") }
    }
    @Published var liveExpanded = false
    @Published private(set) var session = PomodoroSession()
    @Published private(set) var now = Date()
    @Published private(set) var notificationStatus = L10n.tr("Notificações não autorizadas")
    @Published var alertMessage: String?

    private let defaults: UserDefaults
    private let alerts = PomodoroAlerts()
    private var timer: AnyCancellable?
    private var wakeObserver: AnyCancellable?
    private var languageObserver: AnyCancellable?
    private var scheduledDeadline: Date?
    private var currentSound: NSSound?

    var configuration: PomodoroConfiguration {
        PomodoroConfiguration(focusMinutes: focusMinutes, restMinutes: restMinutes,
                              cycleLimit: unlimited ? nil : cycleCount, autoAdvance: autoAdvance)
    }
    var canSkipRest: Bool {
        session.phase == .rest && [.waiting, .running, .paused].contains(session.state)
    }
    var liveVisible: Bool { liveEnabled && session.state != .idle }
    var floatingLiveVisible: Bool { liveVisible && liveStyle == .floating }
    var menuBarLiveVisible: Bool { liveVisible && liveStyle == .menuBar }
    var liveStatusSymbol: String {
        if session.state == .completed { return "checkmark.circle" }
        if session.state == .waiting { return "bell.badge" }
        if session.state == .paused { return "pause.circle" }
        return session.phase == .rest ? "cup.and.saucer" : "timer"
    }
    var canConfigure: Bool { session.state == .idle || session.state == .completed }
    var phaseTitle: String { session.phase == .focus ? L10n.tr("Foco") : L10n.tr("Intervalo") }
    var countdown: String {
        let seconds = Int(ceil(session.remaining(at: now)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    var cycleDescription: String {
        let number = session.state == .completed ? session.completedCycles : min(session.completedCycles, Int.max - 1) + 1
        let limit = canConfigure && session.state == .idle ? configuration.cycleLimit : session.configuration.cycleLimit
        return limit.map { L10n.tr("Ciclo %@ de %@", String(describing: number), String(describing: $0)) } ?? L10n.tr("Ciclo %@ · sem limite", String(describing: number))
    }
    var primaryTitle: String {
        switch session.state {
        case .idle: return L10n.tr("Iniciar foco")
        case .running: return L10n.tr("Pausar")
        case .paused: return L10n.tr("Retomar")
        case .waiting: return session.phase == .rest ? L10n.tr("Iniciar intervalo") : L10n.tr("Iniciar foco")
        case .completed: return L10n.tr("Nova sessão")
        }
    }
    var stateTitle: String {
        switch session.state {
        case .idle: return L10n.tr("Pronto para começar")
        case .running: return L10n.tr("%@ em andamento", String(describing: phaseTitle))
        case .paused: return L10n.tr("%@ pausado", String(describing: phaseTitle))
        case .waiting: return L10n.tr("Hora de %@", String(describing: session.phase == .rest ? L10n.tr("descansar") : L10n.tr("voltar ao foco")))
        case .completed: return L10n.tr("Sessão concluída")
        }
    }
    var plan: PomodoroConfiguration { canConfigure ? configuration : session.configuration }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["pomodoro.focus": 25, "pomodoro.rest": 5,
            "pomodoro.unlimited": false, "pomodoro.cycles": 4, "pomodoro.auto": false,
            "pomodoro.sound": true, "pomodoro.notifications": false, "pomodoro.live": true, "pomodoro.livePinned": true])
        liveEnabled = defaults.bool(forKey: "pomodoro.live")
        livePinned = defaults.bool(forKey: "pomodoro.livePinned")
        liveStyle = PomodoroLiveStyle(rawValue: defaults.string(forKey: "pomodoro.liveStyle") ?? "") ?? .floating
        focusMinutes = min(180, max(1, defaults.integer(forKey: "pomodoro.focus")))
        restMinutes = min(60, max(1, defaults.integer(forKey: "pomodoro.rest")))
        unlimited = defaults.bool(forKey: "pomodoro.unlimited")
        cycleCount = min(99, max(1, defaults.integer(forKey: "pomodoro.cycles")))
        autoAdvance = defaults.bool(forKey: "pomodoro.auto")
        soundEnabled = defaults.bool(forKey: "pomodoro.sound")
        notificationsEnabled = defaults.bool(forKey: "pomodoro.notifications")
        session = PomodoroSession(configuration: configuration)
        alerts.onError = { [weak self] message in self?.alertMessage = message }
        refreshNotificationStatus()
        languageObserver = NotificationCenter.default.publisher(for: .appLanguageChanged)
            .sink { [weak self] _ in
                self?.refreshNotificationStatus()
                self?.synchronizeNotification(force: true)
                self?.objectWillChange.send()
            }
        timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.tick() }
        wakeObserver = NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in self?.tick() }
    }

    private func saveSettings() {
        defaults.set(focusMinutes, forKey: "pomodoro.focus")
        defaults.set(restMinutes, forKey: "pomodoro.rest")
        defaults.set(unlimited, forKey: "pomodoro.unlimited")
        defaults.set(cycleCount, forKey: "pomodoro.cycles")
        defaults.set(autoAdvance, forKey: "pomodoro.auto")
        defaults.set(soundEnabled, forKey: "pomodoro.sound")
        defaults.set(notificationsEnabled, forKey: "pomodoro.notifications")
        if session.state == .idle { session = PomodoroSession(configuration: configuration) }
        synchronizeNotification(force: true)
    }

    func primaryAction() {
        liveExpanded = false
        now = Date()
        switch session.state {
        case .idle, .completed:
            session = PomodoroSession(configuration: configuration)
            session.start(at: now)
        case .running: handle(session.pause(at: now))
        case .paused: session.resume(at: now)
        case .waiting: session.start(at: now)
        }
        synchronizeNotification(force: true)
    }

    /// A live action must never accidentally pause a phase that auto-advanced.
    func continueFromLive() {
        if session.state == .waiting || session.state == .paused || session.state == .completed {
            primaryAction()
        } else {
            liveExpanded = false
        }
    }

    func skipRest() {
        now = Date()
        handle(session.tick(at: now))
        guard canSkipRest else { synchronizeNotification(force: true); return }
        liveExpanded = false
        handle(session.skipRest(at: now))
        synchronizeNotification(force: true)
    }

    func reset() {
        liveExpanded = false
        alerts.cancel()
        scheduledDeadline = nil
        currentSound?.stop()
        session = PomodoroSession(configuration: configuration)
        now = Date()
    }

    func tick(at date: Date = Date()) {
        now = date
        let events = session.tick(at: now)
        handle(events)
        synchronizeNotification()
    }

    private func handle(_ events: [PomodoroSession.Event]) {
        guard !events.isEmpty else { return }
        liveExpanded = true
        guard soundEnabled else { return }
        currentSound?.stop()
        let name = events.contains(.completed) ? "Hero" : (events.contains(.focusFinished) ? "Glass" : "Ping")
        currentSound = NSSound(named: NSSound.Name(name))
        currentSound?.volume = 0.5
        currentSound?.play()
    }

    func previewAlert() {
        currentSound?.stop()
        currentSound = NSSound(named: NSSound.Name(session.phase == .focus ? "Glass" : "Ping"))
        currentSound?.volume = 0.5
        currentSound?.play()
    }

    func authorizeNotifications() {
        alerts.requestPermission { [weak self] granted in
            guard let self else { return }
            self.notificationsEnabled = granted
            self.refreshNotificationStatus()
        }
    }

    func refreshNotificationStatus() {
        alerts.authorizationStatus { [weak self] authorized in
            self?.notificationStatus = authorized ? L10n.tr("Notificações autorizadas") : L10n.tr("Autorize as notificações no macOS")
        }
    }

    private func synchronizeNotification(force: Bool = false) {
        let deadline = notificationsEnabled ? session.phaseEndDate : nil
        guard force || deadline != scheduledDeadline else { return }
        scheduledDeadline = deadline
        alerts.cancel()
        guard let deadline, session.state == .running else { return }
        let lastRest = session.phase == .rest && session.configuration.cycleLimit == min(session.completedCycles, Int.max - 1) + 1
        let title = lastRest ? L10n.tr("Pomodoro concluído") : (session.phase == .focus ? L10n.tr("Hora de fazer uma pausa") : L10n.tr("Hora de voltar ao foco"))
        let body = lastRest ? L10n.tr("Você completou todos os ciclos planejados. Bom trabalho!") :
            (session.configuration.autoAdvance ? L10n.tr("O %@ começou automaticamente.", String(describing: session.phase == .focus ? L10n.tr("intervalo") : L10n.tr("foco"))) :
                L10n.tr("Abra o Keynest para iniciar %@.", String(describing: session.phase == .focus ? L10n.tr("o intervalo") : L10n.tr("o próximo foco"))))
        alerts.schedule(at: deadline, title: title, body: body)
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)min" : "\(minutes) min"
    }
}

/// Notifications are scheduled for the deadline, rather than relying on a visible SwiftUI view.
final class PomodoroAlerts: NSObject, UNUserNotificationCenterDelegate {
    var onError: ((String) -> Void)?
    private let identifier = "mactap.pomodoro.phase"
    // UserNotifications requires an application bundle; don't initialize it in swift test/CLI.
    private var center: UNUserNotificationCenter? {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return nil }
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        return center
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        guard let center else { completion(false); return }
        center.requestAuthorization(options: [.alert]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error { self?.onError?(error.localizedDescription) }
                completion(granted)
            }
        }
    }

    func authorizationStatus(completion: @escaping (Bool) -> Void) {
        guard let center else { completion(false); return }
        center.getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus == .authorized) }
        }
    }

    func schedule(at date: Date, title: String, body: String) {
        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        // Distinct Glass/Ping cues are played by the running app; don't double them here.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)) { [weak self] error in
            if let error { DispatchQueue.main.async { self?.onError?(error.localizedDescription) } }
        }
    }

    func cancel() { center?.removePendingNotificationRequests(withIdentifiers: [identifier]) }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list])
    }

    deinit { cancel() }
}
