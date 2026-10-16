import AVFoundation
import CryptoKit
import XCTest
@testable import MacTap

final class ClickSoundTests: XCTestCase {
    func testAllRecordingsAreBundledAndPlayable() throws {
        for sound in ClickSound.allCases {
            for variation in 0..<ClickSound.variationCount {
                let url = try sound.recordingURL(variation: variation)
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
                let buffer = try sound.loadBuffer(variation: variation)
                XCTAssertEqual(buffer.format.sampleRate, 44100)
                XCTAssertEqual(buffer.format.channelCount, 1)
                let duration = Double(buffer.frameLength) / buffer.format.sampleRate
                XCTAssertTrue((0.04...0.25).contains(duration))
                let channel = try XCTUnwrap(buffer.floatChannelData?[0])
                let samples = Array(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
                XCTAssertTrue(samples.allSatisfy { $0.isFinite && abs($0) <= 0.701 })
                let rms = sqrt(samples.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(samples.count))
                XCTAssertGreaterThan(rms, 0.005)
            }
        }
    }

    func testVariationsAreDistinctRecordings() throws {
        var recordings = Set<Data>()
        for sound in ClickSound.allCases {
            for variation in 0..<ClickSound.variationCount {
                let data = try Data(contentsOf: sound.recordingURL(variation: variation))
                XCTAssertTrue(recordings.insert(data).inserted, "Duplicated recording: \(sound), \(variation)")
            }
        }
        XCTAssertEqual(recordings.count, 12)
    }

    func testOriginalMXBlueRecordingsRemainUnchanged() throws {
        let expected = [
            "45a6cdcafda28488204a8b4dc08cc6061456ffe3637467028f399c77071f3afc",
            "02710810d43a37ad5209641a24c577b485c200998b656653e38e07fc7edef393",
            "d68a43e2dfe2196ebe6feaafed62af4f1b9e2f42fa34c37867c0518ff6438d0c",
            "a36665d49d669effdf7cf2045bb9a4ee119a0e33d2c1ee944327fae1d1b5cb48"
        ]
        for variation in 0..<ClickSound.variationCount {
            let data = try Data(contentsOf: ClickSound.mechanical.recordingURL(variation: variation))
            let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            XCTAssertEqual(digest, expected[variation])
        }
        XCTAssertEqual(ClickSound.allCases.map(\.title), ["Cherry MX Black", "Cherry MX Brown", "Cherry MX Blue"])
    }

    func testVariationIndexWrapsWithoutOverflow() throws {
        for sound in ClickSound.allCases {
            XCTAssertEqual(try sound.recordingURL(variation: 0), try sound.recordingURL(variation: 4))
            XCTAssertEqual(try sound.recordingURL(variation: -1), try sound.recordingURL(variation: 3))
            XCTAssertNoThrow(try sound.recordingURL(variation: Int.min))
            XCTAssertNoThrow(try sound.recordingURL(variation: Int.max))
        }
    }

    func testPlaybackPreservesRecordedWaveform() throws {
        for sound in ClickSound.allCases {
            let file = try AVAudioFile(forReading: sound.recordingURL(variation: 0))
            let original = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                        frameCapacity: AVAudioFrameCount(file.length)))
            try file.read(into: original)
            let played = try sound.loadBuffer(variation: 0)
            XCTAssertEqual(played.frameLength, original.frameLength)
            let input = try XCTUnwrap(original.floatChannelData?[0])
            let output = try XCTUnwrap(played.floatChannelData?[0])
            let count = Int(original.frameLength)
            let peak = (0..<count).reduce(Float(0)) { max($0, abs(input[$1])) }
            let gain = min(8, 0.7 / peak)
            for frame in 0..<count {
                XCTAssertEqual(output[frame], input[frame] * gain, accuracy: 0.000001)
            }
        }
    }
}
