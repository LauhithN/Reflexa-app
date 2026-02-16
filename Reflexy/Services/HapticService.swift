import UIKit
import CoreHaptics
import SwiftUI

/// Centralized haptic feedback service
final class HapticService {
    static let shared = HapticService()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    private var isEnabled: Bool { hapticsEnabled }

    private init() {
        // Pre-warm generators for zero-latency feedback
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }

    /// Light tap feedback (button taps, game taps)
    func lightTap() {
        guard isEnabled else { return }
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    /// Medium impact (countdown beats)
    func countdownBeat() {
        guard isEnabled else { return }
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }

    /// Heavy impact (GO! moment)
    func goImpact() {
        guard isEnabled else { return }
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }

    /// Success notification (wins)
    func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    /// Error notification (false starts)
    func error() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
        notification.prepare()
    }

    /// Warning notification
    func warning() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    /// Vibration stimulus for Vibration Reflex game — always fires regardless of setting
    /// (this IS the game stimulus, not feedback)
    func vibrationStimulus() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            // Fallback to heavy impact
            heavyImpact.impactOccurred()
            return
        }

        do {
            let engine = try CHHapticEngine()
            try engine.start()

            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: 0.3
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            heavyImpact.impactOccurred()
        }
    }
}
