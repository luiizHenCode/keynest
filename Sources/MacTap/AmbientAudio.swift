import AVFoundation
import Foundation

private final class AmbientBundleFinder {}

protocol AmbientPlaying: AnyObject {
    var numberOfLoops: Int { get set }
    var volume: Float { get set }
    var isPlaying: Bool { get }
    func prepareToPlay() -> Bool
    func play() -> Bool
    func pause()
    func stop()
    func setVolume(_ volume: Float, fadeDuration: TimeInterval)
}

extension AVAudioPlayer: AmbientPlaying {}

/// Independent of the keyboard engine: pausing clicks must not stop the ambience.
final class AmbientAudio {
    private var player: (any AmbientPlaying)?
    private var loadedSound: AmbientSound?
    private var fadingPlayers: [UUID: any AmbientPlaying] = [:]
    private var pendingPause: DispatchWorkItem?
    private var enabled = false
    private let makePlayer: (AmbientSound) throws -> any AmbientPlaying

    init(makePlayer: @escaping (AmbientSound) throws -> any AmbientPlaying = {
        try AVAudioPlayer(contentsOf: AmbientAudio.recordingURL(sound: $0))
    }) {
        self.makePlayer = makePlayer
    }

    static func recordingURL(sound: AmbientSound = .rain) throws -> URL {
        let candidates = [Bundle.main.resourceURL, Bundle(for: AmbientBundleFinder.self).resourceURL,
                          Bundle.main.bundleURL, Bundle.main.executableURL?.deletingLastPathComponent()]
        for location in candidates.compactMap({ $0 }) {
            if let bundle = Bundle(url: location.appendingPathComponent("MacTap_MacTap.bundle")),
               let url = bundle.url(forResource: sound.rawValue, withExtension: "wav", subdirectory: "Ambience") {
                return url
            }
        }
        throw PlaybackError.missingRecording(sound.title)
    }

    static func clampedVolume(_ volume: Double) -> Float {
        volume.isFinite ? Float(min(1, max(0, volume))) : 0
    }

    func setEnabled(_ enabled: Bool, sound: AmbientSound = .rain, volume: Double) throws {
        precondition(Thread.isMainThread)
        pendingPause?.cancel()
        pendingPause = nil
        if enabled {
            if player == nil || loadedSound != sound {
                // Prepare and start the replacement before retiring the current track.
                let prepared = try makePlayer(sound)
                prepared.numberOfLoops = -1
                prepared.volume = 0
                guard prepared.prepareToPlay(), prepared.play() else { throw PlaybackError.unavailable }
                if let oldPlayer = player { fadeOut(oldPlayer) }
                player = prepared
                loadedSound = sound
            }
            guard let player else { throw PlaybackError.unavailable }
            if !player.isPlaying {
                player.volume = 0
                guard player.play() else { throw PlaybackError.unavailable }
            }
            self.enabled = true
            player.setVolume(Self.clampedVolume(volume) * sound.playbackGain, fadeDuration: 0.5)
        } else {
            self.enabled = false
            player?.setVolume(0, fadeDuration: 0.35)
            let pause = DispatchWorkItem { [weak self] in
                guard let self, !self.enabled else { return }
                self.player?.pause()
            }
            pendingPause = pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: pause)
        }
    }

    private func fadeOut(_ oldPlayer: any AmbientPlaying) {
        let id = UUID()
        fadingPlayers[id] = oldPlayer
        oldPlayer.setVolume(0, fadeDuration: 0.35)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.fadingPlayers.removeValue(forKey: id)?.stop()
        }
    }

    func setVolume(_ volume: Double) {
        precondition(Thread.isMainThread)
        guard enabled else { return }
        player?.setVolume(Self.clampedVolume(volume) * (loadedSound?.playbackGain ?? 1), fadeDuration: 0.12)
    }

    deinit {
        pendingPause?.cancel()
        player?.stop()
        for player in fadingPlayers.values { player.stop() }
    }

    private enum PlaybackError: LocalizedError {
        case missingRecording(String)
        case unavailable

        var errorDescription: String? {
            switch self {
            case .missingRecording(let name): return L10n.tr("A trilha %@ não foi encontrada. Recompile o app com os recursos de ambiente.", String(describing: name))
            case .unavailable: return L10n.tr("Não foi possível iniciar o som ambiente. Verifique a saída de áudio do macOS.")
            }
        }
    }
}
