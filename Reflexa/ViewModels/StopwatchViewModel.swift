import Foundation
import QuartzCore
import Combine

/// Stopwatch game: Countdown from 100 to 0, stop at exactly 0.
/// Score = abs(stoppedValue). Lower is better.
final class StopwatchViewModel: ObservableObject, GameViewModelProtocol {
    let config: GameConfiguration
    @Published var state: GameState = .ready

    // Display value counting down from 100
    @Published var currentValue: Double = Constants.stopwatchStartValue
    // Per-player stopped values (indexed by player)
    @Published var stoppedValues: [Double?]
    // Per-player stopped state
    @Published var playerStopped: [Bool]

    private let timing = TimingService()
    private let haptic = HapticService.shared
    private var countdownTask: Task<Void, Never>?
    private var pausedState: GameState?

    init(config: GameConfiguration) {
        self.config = config
        self.stoppedValues = Array(repeating: nil, count: config.playerMode.playerCount)
        self.playerStopped = Array(repeating: false, count: config.playerMode.playerCount)
    }

    func startGame() {
        guard state == .ready || state == .result else { return }
        timing.stop()
        countdownTask?.cancel()
        currentValue = Constants.stopwatchStartValue
        stoppedValues = Array(repeating: nil, count: config.playerMode.playerCount)
        playerStopped = Array(repeating: false, count: config.playerMode.playerCount)
        state = .countdown(3)
        runCountdown(from: 3)
    }

    func resetGame() {
        countdownTask?.cancel()
        timing.stop()
        currentValue = Constants.stopwatchStartValue
        stoppedValues = Array(repeating: nil, count: config.playerMode.playerCount)
        playerStopped = Array(repeating: false, count: config.playerMode.playerCount)
        state = .ready
    }

    func playerTapped(index: Int) {
        guard case .active = state else { return }
        guard playerStopped.indices.contains(index), !playerStopped[index] else { return }

        haptic.lightTap()
        playerStopped[index] = true
        stoppedValues[index] = currentValue

        // Check if all players have stopped
        if playerStopped.allSatisfy({ $0 }) {
            timing.stop()
            haptic.success()
            state = .result
        }
    }

    /// Score for a player (lower is better)
    func scoreFor(player: Int) -> Double {
        guard stoppedValues.indices.contains(player) else { return Constants.stopwatchStartValue }
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

    func setPaused(_ paused: Bool) {
        if paused {
            guard pausedState == nil else { return }
            pausedState = state
            countdownTask?.cancel()
            timing.pause()
            return
        }

        guard let pausedState else { return }
        self.pausedState = nil

        switch pausedState {
        case .countdown(let value):
            runCountdown(from: value)
        case .active:
            timing.resume()
        default:
            break
        }
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

        countdownTask?.cancel()
        countdownTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.runCountdown(from: value - 1)
        }
    }

    /// Start the stopwatch countdown from 100 to negative values using CADisplayLink
    private func startStopwatch() {
        timing.start { [weak self] elapsed in
            guard let self else { return }
            // Count down at 25 units per second (100 / 4 seconds = nice speed)
            let newValue = Constants.stopwatchStartValue - (elapsed * 25.0)
            self.currentValue = newValue
        }
    }

    deinit {
        countdownTask?.cancel()
        timing.stop()
    }
}
