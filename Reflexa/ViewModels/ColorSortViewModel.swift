import Foundation
import QuartzCore

/// Color Sort (Stroop Test): A color word appears in mismatched ink.
/// Tap the button matching the INK COLOR, not the word. 15 seconds.
@Observable
final class ColorSortViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    /// 0 = RED, 1 = BLUE, 2 = GREEN, 3 = YELLOW
    var currentWordIndex: Int = 0
    var currentInkIndex: Int = 0

    var correctCount: Int = 0
    var wrongCount: Int = 0
    var timeRemaining: Double = Constants.colorSortDuration
    var showPenaltyFlash: Bool = false

    var accuracy: Double {
        let total = correctCount + wrongCount
        guard total > 0 else { return 0 }
        return Double(correctCount) / Double(total) * 100
    }

    var performanceTier: String {
        switch correctCount {
        case 20...: return "Stroop Master"
        case 14..<20: return "Sharp Mind"
        case 8..<14: return "Getting Warped"
        default: return "Brain Fog"
        }
    }

    private let timing = TimingService()
    private let haptic = HapticService.shared

    init(config: GameConfiguration) {
        self.config = config
    }

    func startGame() {
        guard state == .ready || state == .result else { return }
        resetValues()
        state = .countdown(3)
        runCountdown(from: 3)
    }

    func resetGame() {
        timing.stop()
        resetValues()
        state = .ready
    }

    func playerTapped(index: Int) {
        guard case .active = state, !showPenaltyFlash else { return }

        if index == currentInkIndex {
            // Correct — ink color matches
            haptic.lightTap()
            correctCount += 1
            generateTrial()
        } else {
            // Wrong — penalty flash
            haptic.error()
            wrongCount += 1
            showPenaltyFlash = true

            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.colorSortPenaltyFlashDuration) { [weak self] in
                self?.showPenaltyFlash = false
            }
        }
    }

    // MARK: - Private

    private func resetValues() {
        correctCount = 0
        wrongCount = 0
        timeRemaining = Constants.colorSortDuration
        showPenaltyFlash = false
        generateTrial()
    }

    private func generateTrial() {
        currentWordIndex = Int.random(in: 0..<4)
        var ink = Int.random(in: 0..<4)
        while ink == currentWordIndex {
            ink = Int.random(in: 0..<4)
        }
        currentInkIndex = ink
    }

    private func runCountdown(from value: Int) {
        if value <= 0 {
            haptic.goImpact()
            startTimer()
            return
        }

        state = .countdown(value)
        haptic.countdownBeat()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.runCountdown(from: value - 1)
        }
    }

    private func startTimer() {
        state = .active

        timing.start { [weak self] elapsed in
            guard let self else { return }
            let remaining = Constants.colorSortDuration - elapsed
            if remaining <= 0 {
                self.timeRemaining = 0
                self.timing.stop()
                self.haptic.success()
                self.state = .result
            } else {
                self.timeRemaining = remaining
            }
        }
    }

    deinit {
        timing.stop()
    }
}
