import AppKit
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "enabled")
            updateMonitoring()
        }
    }
    @Published var volume: Double {
        didSet { UserDefaults.standard.set(volume, forKey: "volume") }
    }
    @Published var sound: ClickSound {
        didSet { UserDefaults.standard.set(sound.rawValue, forKey: "sound") }
    }
    @Published var isAmbientEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAmbientEnabled, forKey: "ambientEnabled")
            updateAmbience()
        }
    }
    @Published var ambientSound: AmbientSound {
        didSet {
            UserDefaults.standard.set(ambientSound.rawValue, forKey: "ambientSound")
            updateAmbience()
        }
    }
    @Published var ambientVolume: Double {
        didSet {
            UserDefaults.standard.set(ambientVolume, forKey: "ambientVolume")
            ambience.setVolume(ambientVolume)
        }
    }
    @Published private(set) var hasPermission = false
    @Published private(set) var isMonitoring = false
    @Published var errorMessage: String?
    @Published private(set) var detectedKeyCount = 0
    var isTestingKeyboard = false

    private let monitor = KeyboardMonitor()
    private let audio = KeyboardAudio()
    private let ambience = AmbientAudio()
    private var permissionTimer: AnyCancellable?

    var status: String {
        if !isEnabled { return L10n.tr("Em pausa") }
        if !hasPermission { return L10n.tr("Permissão necessária") }
        return isMonitoring ? L10n.tr("Ativo") : L10n.tr("Indisponível")
    }

    init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: ["enabled": false, "volume": 0.45, "sound": "soft",
                                     "ambientEnabled": false, "ambientVolume": 0.25, "ambientSound": "rain"])
        isAmbientEnabled = defaults.bool(forKey: "ambientEnabled")
        ambientSound = AmbientSound(rawValue: defaults.string(forKey: "ambientSound") ?? "") ?? .rain
        let savedAmbientVolume = defaults.double(forKey: "ambientVolume")
        ambientVolume = savedAmbientVolume.isFinite ? min(1, max(0, savedAmbientVolume)) : 0.25
        isEnabled = defaults.bool(forKey: "enabled")
        let savedVolume = defaults.double(forKey: "volume")
        volume = savedVolume.isFinite ? min(1, max(0, savedVolume)) : 0.45
        sound = ClickSound(rawValue: defaults.string(forKey: "sound") ?? "") ?? .soft
        monitor.onKeyDown = { [weak self] in
            guard let self, self.isEnabled else { return }
            self.playDetectedKey()
        }
        monitor.onLocalKeyDown = { [weak self] in
            guard let self, self.isEnabled || self.isTestingKeyboard else { return }
            self.playDetectedKey()
        }
        monitor.startLocal()
        audio.onError = { [weak self] message in self?.errorMessage = message }
        updateMonitoring()
        updateAmbience()
        permissionTimer = Timer.publish(every: 2, on: .main, in: .common)
            .autoconnect().sink { [weak self] _ in
                guard let self else { return }
                if self.monitor.hasPermission != self.hasPermission ||
                    (self.isEnabled && self.hasPermission && !self.monitor.isRunning) {
                    self.updateMonitoring()
                }
            }
    }

    private func updateAmbience() {
        do {
            try ambience.setEnabled(isAmbientEnabled, sound: ambientSound, volume: ambientVolume)
        } catch {
            errorMessage = error.localizedDescription
            if isAmbientEnabled { isAmbientEnabled = false }
        }
    }

    func updateMonitoring() {
        hasPermission = monitor.hasPermission
        if isEnabled && hasPermission {
            isMonitoring = monitor.start()
            if !isMonitoring {
                errorMessage = L10n.tr("Não foi possível ouvir o teclado. Verifique a permissão e encerre e abra o Keynest novamente.")
            }
        } else {
            monitor.stop()
            audio.stop()
            isMonitoring = false
        }
    }

    func requestPermission() {
        monitor.requestPermission()
        isEnabled = true
        if !hasPermission { openPrivacySettings() }
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else { return }
        NSWorkspace.shared.open(url)
    }

    private func playDetectedKey() {
        detectedKeyCount += 1
        audio.play(sound, volume: volume)
    }

    func preview(_ selected: ClickSound? = nil) {
        audio.play(selected ?? sound, volume: volume)
    }
}
