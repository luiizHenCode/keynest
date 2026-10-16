import AVFoundation
import Foundation

private final class RecordingBundleFinder {}

enum ClickSound: String, CaseIterable, Identifiable {
    case soft
    case thock
    case mechanical

    static let variationCount = 4
    var id: String { rawValue }

    var title: String {
        switch self {
        case .soft: return "Cherry MX Black"
        case .thock: return "Cherry MX Brown"
        case .mechanical: return "Cherry MX Blue"
        }
    }

    var subtitle: String {
        switch self {
        case .soft: return L10n.tr("Linear · batida mais seca")
        case .thock: return L10n.tr("Tátil · toque equilibrado")
        case .mechanical: return L10n.tr("Clicky · clique marcado")
        }
    }

    var symbol: String {
        switch self {
        case .soft: return "line.3.horizontal"
        case .thock: return "waveform"
        case .mechanical: return "keyboard"
        }
    }

    func recordingURL(variation: Int) throws -> URL {
        let index = (variation % Self.variationCount + Self.variationCount) % Self.variationCount
        let name = "\(rawValue)-\(index)"
        // App bundles, XCTest and `swift run` place resources in different locations.
        // Resolve explicitly so a missing bundle throws an actionable error, not a SwiftPM fatalError.
        let candidates = [Bundle.main.resourceURL, Bundle(for: RecordingBundleFinder.self).resourceURL,
                          Bundle.main.bundleURL, Bundle.main.executableURL?.deletingLastPathComponent()]
        let resources = candidates.compactMap { location in
            location.flatMap { Bundle(url: $0.appendingPathComponent("MacTap_MacTap.bundle")) }
        }.first
        guard let url = resources?.url(forResource: name, withExtension: "wav", subdirectory: "KeyboardSounds") else {
            throw RecordingError.missing(name)
        }
        return url
    }

    func loadBuffer(variation: Int) throws -> AVAudioPCMBuffer {
        let file = try AVAudioFile(forReading: recordingURL(variation: variation))
        guard file.length > 0, file.length <= 44100,
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                             frameCapacity: AVAudioFrameCount(file.length)) else {
            throw RecordingError.invalid(title)
        }
        try file.read(into: buffer)
        guard let channel = buffer.floatChannelData?[0] else { throw RecordingError.invalid(title) }
        // Match levels without changing the recorded pitch or transient shape.
        let count = Int(buffer.frameLength)
        let peak = (0..<count).reduce(Float(0)) { max($0, abs(channel[$1])) }
        guard peak > 0, peak.isFinite else { throw RecordingError.invalid(title) }
        let gain: Float = min(8, 0.7 / peak)
        for frame in 0..<count { channel[frame] *= gain }
        return buffer
    }

    private enum RecordingError: LocalizedError {
        case missing(String)
        case invalid(String)

        var errorDescription: String? {
            switch self {
            case .missing(let name): return L10n.tr("Gravação %@.wav ausente. Recompile o aplicativo com seus recursos de áudio.", String(describing: name))
            case .invalid(let name): return L10n.tr("A gravação de %@ não pôde ser carregada.", String(describing: name))
            }
        }
    }
}
