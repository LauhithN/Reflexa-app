import Foundation
import QuartzCore

/// Stopwatch game: Countdown from 100 to 0, stop at exactly 0.
/// Score = abs(stoppedValue). Lower is better.
@Observable
final class StopwatchViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    // Display value counting down from 100
    var currentValue: Double = Constants.stopwatchStartValue
    // Per-player stopped values (indexed by player)
    var stoppedValues: [Double?]
    // Per-player stopped state
    var playerStopped: [Bool]

    private let timing = TimingService()
    private let haptic = HapticService.shared
    private var countdownTimer: TimingService?

    init(config: GameConfiguration) {
        self.config = config
        self.stoppedValues = Array(repeating: nil, count: config.playerMode.playerCount)
        self.playerStopped = Array(repeating: false, count: config.playerMode.playerCount)
    }

    func startGame() {
        guard state == .ready || state == .result else { return }
        state = .countdown(3)
        runCountdown(from: 3)
    }

    func resetGame() {
        timing.stop()
        currentValue = Constants.stopwatchStartValue
        stoppedValues = Array(repeating: nil, count: config.playerMode.playerCount)
        playerStopped = Array(repeating: false, count: config.playerMode.playerCount)
        state = .ready
    }

    func playerTapped(index: Int) {
        guard case .active = state else { return }
        guard index < playerStopped.count, !playerStopped[index] else { return }

        haptic.lightTap()
        playerStopped[index] = true
        stoppedValues[index] = currentValue

        // Check if all players have stopped
        if playerStopped.allSatisfy({ $0 }) {
            timing.stop()
            state = .result
            haptic.success()
        }
    }

    /// Score for a player (lower is better)
    func scoreFor(player: Int) -> Double {
        guard let value = stoppedValues[player] else { return Constants.stopwatchStartValue }
        return abs(value)
    }

    /// Winner index (lowest score)
    var winnerIndex: Int? {
        guard config.playerMode != .solo else { return nil }
        guard stoppedValues.allSatisfy({ $0 != nil }) else { return nil }

        var bestIndex = 0
        var bestScore = Double.infinity
        for i in 0..<stoppedValues.count {
            let score = scoreFor(player: i)
            if score < bestScore {
                bestScore = score
                bestIndex = i
            }
        }
        return bestIndex
    }

    // MARK: - Private

    private func runCountdown(from value: Int) {
        if value <= 0 {
            state = .active
            haptic.goImpact()
            startStopwatch()
            return
        }

        state = .countdown(value)
        haptic.countdownBeat()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.runCountdown(from: value - 1)
        }
    }

    /// Start the stopwatch countdown from 100 to negative values using CADisplayLink
    private func startStopwatch() {
        let startTime = CACurrentMediaTime()
        timing.start { [weak self] elapsed in
            guard let self else { return }
            // Count down at 25 units per second (100 / 4 seconds = nice speed)
            let newValue = Constants.stopwatchStartValue - (elapsed * 25.0)
            self.currentValue = newValue
        }
    }

    deinit {
        timing.stop()
    }
}
