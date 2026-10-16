import AppKit
import Combine

struct StatusBarPresentation: Equatable {
    static let iconWidth: CGFloat = 30
    static let timerWidth: CGFloat = 74
    let timerText: String?
    let tooltip: String
    var width: CGFloat { timerText == nil ? Self.iconWidth : Self.timerWidth }
}

/// The status title can tick independently; menu contents stay unchanged during tracking.
@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private var item: NSStatusItem?
    private let menu = NSMenu()
    private var observations: Set<AnyCancellable> = []
    private weak var model: AppModel?
    private weak var pomodoro: PomodoroModel?
    private var openSettings: (() -> Void)?
    private var presentation: StatusBarPresentation?

    func connect(model: AppModel, pomodoro: PomodoroModel, openSettings: @escaping () -> Void) {
        self.openSettings = openSettings
        guard self.model !== model || self.pomodoro !== pomodoro else { return }
        observations.removeAll()
        self.model = model
        self.pomodoro = pomodoro
        if item == nil {
            item = NSStatusBar.system.statusItem(withLength: StatusBarPresentation.iconWidth)
            menu.delegate = self
            menu.autoenablesItems = false
            item?.menu = menu
            if let button = item?.button {
                let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keynest")
                image?.size = NSSize(width: 16, height: 16)
                image?.isTemplate = true
                button.image = image
                button.imagePosition = .imageLeading
                button.imageScaling = .scaleProportionallyDown
                button.setAccessibilityLabel("Keynest")
            }
        }
        model.objectWillChange.sink { [weak self] _ in
            self?.scheduleStatusUpdate()
        }.store(in: &observations)
        pomodoro.objectWillChange.sink { [weak self] _ in
            self?.scheduleStatusUpdate()
        }.store(in: &observations)
        NotificationCenter.default.publisher(for: .appLanguageChanged).sink { [weak self] _ in
            self?.scheduleStatusUpdate()
        }.store(in: &observations)
        updateStatus()
    }

    private func scheduleStatusUpdate() {
        // Defer until @Published has committed, but also run during NSMenu event tracking.
        // Combine's receive(on: RunLoop.main) uses the default mode, which stalls here.
        Self.scheduleForMenuTracking { [weak self] in self?.updateStatus() }
    }

    static func scheduleForMenuTracking(_ update: @escaping () -> Void) {
        RunLoop.main.perform(inModes: [.common]) { update() }
    }

    private func updateStatus() {
        guard let model, let pomodoro, let item, let button = item.button else { return }
        let next = StatusBarPresentation(
            timerText: pomodoro.menuBarLiveVisible ? (pomodoro.session.state == .completed ? L10n.tr("Feito") : pomodoro.countdown) : nil,
            tooltip: pomodoro.menuBarLiveVisible
                ? "Keynest · \(pomodoro.stateTitle) · \(pomodoro.countdown)"
                : "Keynest · \(model.status)"
        )
        guard next != presentation else { return }
        if next.width != presentation?.width { item.length = next.width }
        if next.timerText != presentation?.timerText {
            let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
            button.attributedTitle = NSAttributedString(string: next.timerText.map { " \($0)" } ?? "",
                                                        attributes: [.font: font, .foregroundColor: NSColor.labelColor])
        }
        button.toolTip = next.tooltip
        button.setAccessibilityValue(next.tooltip)
        presentation = next
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        guard let model, let pomodoro else { return }
        menu.removeAllItems()
        heading("Keynest · \(model.status)")
        command(L10n.tr("Sons do teclado"), checked: model.isEnabled) { model.isEnabled.toggle() }
        submenu(L10n.tr("Teclado")) { child in
            for sound in ClickSound.allCases {
                self.command(sound.title, in: child, checked: model.sound == sound) { model.sound = sound }
            }
        }
        command(L10n.tr("Ouvir exemplo")) { model.preview() }
        menu.addItem(.separator())
        command(L10n.tr("Trilha ambiente"), checked: model.isAmbientEnabled) { model.isAmbientEnabled.toggle() }
        submenu(L10n.tr("Ambiente")) { child in
            for sound in AmbientSound.allCases {
                self.command(sound.title, in: child, checked: model.ambientSound == sound) { model.ambientSound = sound }
            }
        }
        submenu(L10n.tr("Volume do ambiente · %@%%", String(describing: Int(model.ambientVolume * 100)))) { child in
            for (title, level) in [(L10n.tr("Baixinho · 15%"), 0.15), (L10n.tr("Suave · 25%"), 0.25), (L10n.tr("Médio · 50%"), 0.5)] {
                self.command(title, in: child, checked: abs(model.ambientVolume - level) < 0.001) { model.ambientVolume = level }
            }
        }
        menu.addItem(.separator())
        heading("Pomodoro · \(pomodoro.stateTitle) · \(pomodoro.countdown)")
        heading(pomodoro.cycleDescription)
        let displayedState = pomodoro.session.state
        let displayedPhase = pomodoro.session.phase
        command(pomodoro.primaryTitle) {
            // A phase may finish while this snapshot menu is open. Never turn a stale
            // "Start interval" click into "Pause focus" on the newly running phase.
            guard pomodoro.session.state == displayedState, pomodoro.session.phase == displayedPhase else { return }
            pomodoro.primaryAction()
        }
        command(L10n.tr("Modo live do Pomodoro"), checked: pomodoro.liveEnabled) { pomodoro.liveEnabled.toggle() }
        submenu(L10n.tr("Exibir timer")) { child in
            for style in PomodoroLiveStyle.allCases {
                self.command(style.title, in: child, checked: pomodoro.liveStyle == style) { pomodoro.liveStyle = style }
            }
        }
        if pomodoro.floatingLiveVisible {
            command(L10n.tr("Expandir timer flutuante")) { pomodoro.liveExpanded = true }
            command(L10n.tr("Fixar timer no topo"), checked: pomodoro.livePinned) { pomodoro.livePinned.toggle() }
        }
        if pomodoro.canSkipRest { command(L10n.tr("Pular intervalo")) { pomodoro.skipRest() } }
        if !pomodoro.canConfigure { command(L10n.tr("Encerrar sessão de foco")) { pomodoro.reset() } }
        menu.addItem(.separator())
        submenu(L10n.tr("Idioma")) { child in
            for language in AppLanguage.allCases {
                self.command(language.title, in: child, checked: LanguageSettings.shared.selection == language) {
                    LanguageSettings.shared.selection = language
                }
            }
        }
        command(L10n.tr("Abrir Keynest"), key: ",") { [weak self] in self?.openSettings?() }
        command(L10n.tr("Encerrar Keynest"), key: "q") { NSApplication.shared.terminate(nil) }
    }

    private func heading(_ title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func submenu(_ title: String, build: (NSMenu) -> Void) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let child = NSMenu(title: title)
        child.autoenablesItems = false
        build(child)
        item.submenu = child
        menu.addItem(item)
    }

    private func command(_ title: String, in targetMenu: NSMenu? = nil, checked: Bool? = nil,
                         key: String = "", action: @escaping () -> Void) {
        let handler = MenuCommand(action)
        let item = NSMenuItem(title: title, action: #selector(MenuCommand.invokeMenuAction), keyEquivalent: key)
        item.target = handler
        item.representedObject = handler // NSMenuItem's target is weak.
        if let checked { item.state = checked ? .on : .off }
        item.isEnabled = true
        (targetMenu ?? menu).addItem(item)
    }
}

@MainActor
private final class MenuCommand: NSObject {
    private let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
    @objc func invokeMenuAction() { action() }
}
