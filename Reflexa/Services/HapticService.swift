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

    private func performOnMain(_ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }

    private init() {
        // Pre-warm generators for zero-latency feedback
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }

    /// Light tap feedback (button taps, game taps)
    func lightTap() {
        performOnMain { [weak self] in
            guard let self, self.isEnabled else { return }
            self.lightImpact.impactOccurred()
            self.lightImpact.prepare()
        }
    }

    /// Medium impact (countdown beats)
    func countdownBeat() {
        performOnMain { [weak self] in
            guard let self, self.isEnabled else { return }
            self.mediumImpact.impactOccurred()
            self.mediumImpact.prepare()
        }
    }

    /// Heavy impact (GO! moment)
    func goImpact() {
        performOnMain { [weak self] in
            guard let self, self.isEnabled else { return }
            self.heavyImpact.impactOccurred()
            self.heavyImpact.prepare()
        }
    }

    /// Success notification (wins)
    func success() {
        performOnMain { [weak self] in
            guard let self, self.isEnabled else { return }
            self.notification.notificationOccurred(.success)
            self.notification.prepare()
        }
    }

    /// Error notification (false starts)
    func error() {
        performOnMain { [weak self] in
            guard let self, self.isEnabled else { return }
            self.notification.notificationOccurred(.error)
            self.notification.prepare()
        }
    }

    /// Warning notification
    func warning() {
        performOnMain { [weak self] in
            guard let self, self.isEnabled else { return }
            self.notification.notificationOccurred(.warning)
            self.notification.prepare()
        }
    }

    /// Vibration stimulus for Vibration Reflex game — always fires regardless of setting
    /// (this IS the game stimulus, not feedback)
    func vibrationStimulus() {
        performOnMain { [weak self] in
            guard let self else { return }
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
                // Fallback to heavy impact
                self.heavyImpact.impactOccurred()
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
                self.heavyImpact.impactOccurred()
            }
        }
    }
}
