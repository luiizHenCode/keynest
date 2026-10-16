import AVFoundation
import Foundation

/// Main-thread-only audio playback through the system's default output device.
final class KeyboardAudio {
    var onError: ((String) -> Void)?

    private struct BufferKey: Hashable {
        let sound: ClickSound
        let variation: Int
    }

    private let engine = AVAudioEngine()
    private let sampleRate = 44100.0
    private let variationCount = ClickSound.variationCount
    private let voiceCount = 12
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [BufferKey: AVAudioPCMBuffer] = [:]
    private var nextVoice = 0
    private var nextVariation = 0

    // Creating an instance does not configure or start the audio engine.
    func play(_ sound: ClickSound, volume: Double) {
        precondition(Thread.isMainThread, "KeyboardAudio deve ser usado na thread principal.")
        let level = volume.isNaN ? 0 : max(0, min(1, volume))
        guard level > 0 else { return }
        guard prepareIfNeeded() else { return }

        let key = BufferKey(sound: sound, variation: nextVariation)
        guard let buffer = buffers[key] else {
            onError?(L10n.tr("Não foi possível encontrar o som preparado."))
            return
        }

        if !engine.isRunning {
            do {
                engine.prepare()
                try engine.start()
            } catch {
                onError?(L10n.tr("Não foi possível iniciar a saída de áudio: %@", String(describing: error.localizedDescription)))
                return
            }
        }

        // At capacity, reuse the oldest voice instead of allocating on every keystroke.
        let player = players[nextVoice]
        player.stop()
        player.volume = Float(level)
        player.scheduleBuffer(buffer, at: nil, options: [])
        player.play()
        nextVoice = (nextVoice + 1) % players.count
        nextVariation = (nextVariation + 1) % variationCount
    }

    func stop() {
        precondition(Thread.isMainThread, "KeyboardAudio deve ser usado na thread principal.")
        for player in players {
            player.stop()
        }
        engine.stop()
        nextVoice = 0
        nextVariation = 0
    }

    private func prepareIfNeeded() -> Bool {
        guard players.isEmpty else { return true }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            onError?(L10n.tr("Não foi possível criar o formato de áudio."))
            return false
        }

        // Build the entire cache before attaching nodes so a failure leaves setup retryable.
        var prepared: [BufferKey: AVAudioPCMBuffer] = [:]
        for sound in ClickSound.allCases {
            for variation in 0..<variationCount {
                do {
                    prepared[BufferKey(sound: sound, variation: variation)] = try sound.loadBuffer(variation: variation)
                } catch {
                    onError?(error.localizedDescription)
                    return false
                }
            }
        }

        for _ in 0..<voiceCount {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        buffers = prepared
        return true
    }
}
