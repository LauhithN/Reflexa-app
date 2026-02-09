import Foundation
import QuartzCore

/// Quick Tap: Tap as many times as possible in 10 seconds.
/// Score = tap count. Higher is better.
@Observable
final class QuickTapViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    var tapCount: Int = 0
    var timeRemaining: Double = Constants.quickTapDuration
    var isFinished: Bool = false

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
        guard case .active = state else { return }
        haptic.lightTap()
        tapCount += 1
    }

    // MARK: - Private

    private func resetValues() {
        tapCount = 0
        timeRemaining = Constants.quickTapDuration
        isFinished = false
    }

    private func runCountdown(from value: Int) {
        if value <= 0 {
            haptic.goImpact()
            startTapping()
            return
        }

        state = .countdown(value)
        haptic.countdownBeat()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.runCountdown(from: value - 1)
        }
    }

    private func startTapping() {
        state = .active

        timing.start { [weak self] elapsed in
            guard let self else { return }
            let remaining = Constants.quickTapDuration - elapsed
            if remaining <= 0 {
                self.timeRemaining = 0
                self.timing.stop()
                self.isFinished = true
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
