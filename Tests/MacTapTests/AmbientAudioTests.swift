import AVFoundation
import XCTest
@testable import MacTap

final class AmbientAudioTests: XCTestCase {
    func testRainRecordingIsBundledAndDecodesCompletely() throws {
        let url = try AmbientAudio.recordingURL()
        let file = try AVAudioFile(forReading: url)
        XCTAssertEqual(file.processingFormat.sampleRate, 44100)
        XCTAssertEqual(file.processingFormat.channelCount, 1)
        XCTAssertEqual(file.length, 30 * 44100)
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                  frameCapacity: AVAudioFrameCount(file.length)))
        try file.read(into: buffer)
        XCTAssertEqual(AVAudioFramePosition(buffer.frameLength), file.length)
        let channel = try XCTUnwrap(buffer.floatChannelData?[0])
        var energy = 0.0
        var peak: Float = 0
        for frame in 0..<Int(buffer.frameLength) {
            XCTAssertTrue(channel[frame].isFinite)
            peak = max(peak, abs(channel[frame]))
            energy += Double(channel[frame]) * Double(channel[frame])
        }
        XCTAssertGreaterThan(sqrt(energy / Double(buffer.frameLength)), 0.005)
        XCTAssertLessThan(peak, 0.95)
        XCTAssertLessThan(abs(channel[0] - channel[Int(buffer.frameLength) - 1]), 0.02)
        let bytes = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber
        XCTAssertLessThan(try XCTUnwrap(bytes).intValue, 5_000_000)
    }

    func testAmbientPlayerCanPrepareAnInfiniteLoopWithoutPlaying() throws {
        let player = try AVAudioPlayer(contentsOf: AmbientAudio.recordingURL())
        player.numberOfLoops = -1
        XCTAssertEqual(player.numberOfLoops, -1)
        XCTAssertEqual(player.duration, 30, accuracy: 0.001)
        XCTAssertFalse(player.isPlaying)
    }

    func testEveryTrackDecodesAndHasCredits() throws {
        XCTAssertEqual(AmbientSound.allCases.count, 4)
        for sound in AmbientSound.allCases {
            let file = try AVAudioFile(forReading: AmbientAudio.recordingURL(sound: sound))
            XCTAssertEqual(file.processingFormat.sampleRate, 44100)
            XCTAssertEqual(file.processingFormat.channelCount, 1)
            XCTAssertTrue((20...90).contains(Double(file.length) / 44100))
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                                      frameCapacity: AVAudioFrameCount(file.length)))
            try file.read(into: buffer)
            XCTAssertEqual(AVAudioFramePosition(buffer.frameLength), file.length)
            let channel = try XCTUnwrap(buffer.floatChannelData?[0])
            let count = Int(buffer.frameLength)
            var energy = 0.0
            for frame in 0..<count {
                let sample = channel[frame]
                XCTAssertTrue(sample.isFinite && abs(sample) < 0.95)
                energy += Double(sample) * Double(sample)
            }
            XCTAssertGreaterThan(sqrt(energy / Double(count)), 0.005)
            XCTAssertLessThan(abs(channel[0] - channel[count - 1]), 0.05)
            XCTAssertFalse(sound.attribution.isEmpty)
            XCTAssertEqual(sound.sourceURL.scheme, "https")
            XCTAssertEqual(sound.licenseURL.scheme, "https")
        }
    }

    func testSwitchingTracksCrossfadesAndStopsOldPlayer() throws {
        let rain = FakeAmbientPlayer()
        let lofi = FakeAmbientPlayer()
        let audio = AmbientAudio { $0 == .rain ? rain : lofi }
        try audio.setEnabled(true, sound: .rain, volume: 0.25)
        XCTAssertTrue(rain.isPlaying)
        XCTAssertEqual(rain.numberOfLoops, -1)
        try audio.setEnabled(true, sound: .lofi, volume: 0.25)
        XCTAssertEqual(rain.volume, 0)
        XCTAssertTrue(lofi.isPlaying)
        XCTAssertEqual(lofi.volume, 0.25 * AmbientSound.lofi.playbackGain, accuracy: 0.0001)
        audio.setVolume(0.5)
        XCTAssertEqual(lofi.volume, 0.5 * AmbientSound.lofi.playbackGain, accuracy: 0.0001)

        let finished = expectation(description: "Old track retires after its fade")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            XCTAssertFalse(rain.isPlaying)
            XCTAssertEqual(rain.stopCount, 1)
            XCTAssertTrue(lofi.isPlaying)
            finished.fulfill()
        }
        wait(for: [finished], timeout: 2)
        withExtendedLifetime(audio) {}
    }

    func testDisabledSelectionDoesNotLoadOrStartAudio() throws {
        var loadCount = 0
        let player = FakeAmbientPlayer()
        let audio = AmbientAudio { _ in loadCount += 1; return player }
        try audio.setEnabled(false, sound: .forest, volume: 0.25)
        try audio.setEnabled(false, sound: .lofi, volume: 0.25)
        XCTAssertEqual(loadCount, 0)
        XCTAssertFalse(player.isPlaying)
    }

    func testQuickResumeCancelsPendingPauseAndReusesPlayer() throws {
        var loadCount = 0
        let player = FakeAmbientPlayer()
        let audio = AmbientAudio { _ in loadCount += 1; return player }
        try audio.setEnabled(true, sound: .ocean, volume: 0.25)
        try audio.setEnabled(false, sound: .ocean, volume: 0.25)
        try audio.setEnabled(true, sound: .ocean, volume: 0.25)
        let finished = expectation(description: "Cancelled pause does not stop resumed audio")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            XCTAssertTrue(player.isPlaying)
            XCTAssertEqual(player.pauseCount, 0)
            XCTAssertEqual(loadCount, 1)
            finished.fulfill()
        }
        wait(for: [finished], timeout: 2)
        withExtendedLifetime(audio) {}
    }

    func testFailedReplacementDoesNotStopCurrentTrack() throws {
        let rain = FakeAmbientPlayer()
        let invalid = FakeAmbientPlayer()
        invalid.canPrepare = false
        let audio = AmbientAudio { $0 == .rain ? rain : invalid }
        try audio.setEnabled(true, sound: .rain, volume: 0.25)
        XCTAssertThrowsError(try audio.setEnabled(true, sound: .lofi, volume: 0.25))
        XCTAssertTrue(rain.isPlaying)
        XCTAssertEqual(rain.volume, 0.25)
        XCTAssertFalse(invalid.isPlaying)
    }

    func testVolumeIsBoundedAndRejectsNonFiniteValues() {
        XCTAssertEqual(AmbientAudio.clampedVolume(-0.5), 0)
        XCTAssertEqual(AmbientAudio.clampedVolume(2), 1)
        XCTAssertEqual(AmbientAudio.clampedVolume(0.25), 0.25)
        XCTAssertEqual(AmbientAudio.clampedVolume(.nan), 0)
        XCTAssertEqual(AmbientAudio.clampedVolume(.infinity), 0)
        XCTAssertEqual(AmbientAudio.clampedVolume(-.infinity), 0)
    }
}

private final class FakeAmbientPlayer: AmbientPlaying {
    var numberOfLoops = 0
    var volume: Float = 0
    var isPlaying = false
    var canPrepare = true
    var stopCount = 0
    var pauseCount = 0

    func prepareToPlay() -> Bool { canPrepare }
    func play() -> Bool { isPlaying = true; return true }
    func pause() { isPlaying = false; pauseCount += 1 }
    func stop() { isPlaying = false; stopCount += 1 }
    func setVolume(_ volume: Float, fadeDuration: TimeInterval) { self.volume = volume }
}
