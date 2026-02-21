import AVFoundation
import OSLog
import SwiftUI

/// Audio playback service for game sounds.
/// Pre-loads sounds during .ready state to avoid first-play latency.
final class SoundService {
    static let shared = SoundService()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.lauhithnatarajan.reflexa.app", category: "SoundService")

    private var beepPlayer: AVAudioPlayer?
    private var countdownPlayer: AVAudioPlayer?

    @AppStorage("soundEnabled") private var soundEnabled = true

    private var isEnabled: Bool { soundEnabled }

    private func performOnMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        performOnMain {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                self.logger.error("Audio session configuration failed: \(String(describing: error), privacy: .private)")
            }
        }
    }

    /// Pre-load the beep sound (call during .ready state)
    func preloadBeep() {
        performOnMain { [weak self] in
            guard let self else { return }
            self.beepPlayer = self.createTonePlayer(frequency: 880, duration: 0.15)
            self.beepPlayer?.prepareToPlay()
        }
    }

    /// Pre-load countdown tick sound
    func preloadCountdown() {
        performOnMain { [weak self] in
            guard let self else { return }
            self.countdownPlayer = self.createTonePlayer(frequency: 440, duration: 0.1)
            self.countdownPlayer?.prepareToPlay()
        }
    }

    /// Play the beep stimulus for Sound Reflex
    func playBeep() {
        performOnMain { [weak self] in
            guard let self, self.isEnabled else { return }
            self.beepPlayer?.currentTime = 0
            self.beepPlayer?.play()
        }
    }

    /// Play countdown tick
    func playCountdownTick() {
        performOnMain { [weak self] in
            guard let self, self.isEnabled else { return }
            self.countdownPlayer?.currentTime = 0
            self.countdownPlayer?.play()
        }
    }

    /// Generate a sine wave tone programmatically (no asset files needed)
    private func createTonePlayer(frequency: Double, duration: Double) -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let samples = Int(sampleRate * duration)
        var audioData = [Float](repeating: 0, count: samples)

        for i in 0..<samples {
            let t = Double(i) / sampleRate
            // Sine wave with fade-in/out envelope to avoid clicks
            let envelope: Float
            let fadeLength = min(samples / 10, 500)
            if i < fadeLength {
                envelope = Float(i) / Float(fadeLength)
            } else if i > samples - fadeLength {
                envelope = Float(samples - i) / Float(fadeLength)
            } else {
                envelope = 1.0
            }
            audioData[i] = sin(Float(2.0 * .pi * frequency * t)) * envelope * 0.5
        }

        // Build WAV data
        let dataSize = samples * 2 // 16-bit = 2 bytes per sample
        let headerSize = 44
        var wavData = Data(count: headerSize + dataSize)

        // WAV header
        wavData.replaceSubrange(0..<4, with: "RIFF".data(using: .ascii) ?? Data())
        withUnsafeBytes(of: UInt32(headerSize + dataSize - 8).littleEndian) { wavData.replaceSubrange(4..<8, with: $0) }
        wavData.replaceSubrange(8..<12, with: "WAVE".data(using: .ascii) ?? Data())
        wavData.replaceSubrange(12..<16, with: "fmt ".data(using: .ascii) ?? Data())
        withUnsafeBytes(of: UInt32(16).littleEndian) { wavData.replaceSubrange(16..<20, with: $0) }
        withUnsafeBytes(of: UInt16(1).littleEndian) { wavData.replaceSubrange(20..<22, with: $0) } // PCM
        withUnsafeBytes(of: UInt16(1).littleEndian) { wavData.replaceSubrange(22..<24, with: $0) } // Mono
        withUnsafeBytes(of: UInt32(44100).littleEndian) { wavData.replaceSubrange(24..<28, with: $0) }
        withUnsafeBytes(of: UInt32(88200).littleEndian) { wavData.replaceSubrange(28..<32, with: $0) }
        withUnsafeBytes(of: UInt16(2).littleEndian) { wavData.replaceSubrange(32..<34, with: $0) }
        withUnsafeBytes(of: UInt16(16).littleEndian) { wavData.replaceSubrange(34..<36, with: $0) }
        wavData.replaceSubrange(36..<40, with: "data".data(using: .ascii) ?? Data())
        withUnsafeBytes(of: UInt32(dataSize).littleEndian) { wavData.replaceSubrange(40..<44, with: $0) }

        // Audio samples (16-bit)
        for i in 0..<samples {
            let sample = Int16(audioData[i] * 32767)
            let offset = headerSize + i * 2
            withUnsafeBytes(of: sample.littleEndian) { wavData.replaceSubrange(offset..<offset+2, with: $0) }
        }

        return try? AVAudioPlayer(data: wavData)
    }
}
