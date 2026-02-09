import Foundation
import QuartzCore

/// Reaction Duel: Like Color Battle but measures exact reaction times.
/// Winner = fastest time. Single round.
@Observable
final class ReactionDuelViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    var reactionTimes: [Int?] // ms per player, nil = not yet tapped
    var winnerIndex: Int?
    var falseStartPlayer: Int?

    private var stimulusTime: CFTimeInterval = 0
    private var waitTask: Task<Void, Never>?
    private let haptic = HapticService.shared
    private var hasFalseStart = false

    init(config: GameConfiguration) {
        self.config = config
        self.reactionTimes = Array(repeating: nil, count: config.playerMode.playerCount)
    }

    func startGame() {
        guard state == .ready || state == .result else { return }
        if case .falseStart = state { } else if state != .ready && state != .result { return }
        resetValues()
        state = .countdown(3)
        runCountdown(from: 3)
    }

    func resetGame() {
        waitTask?.cancel()
        resetValues()
        state = .ready
    }

    func playerTapped(index: Int) {
        guard !hasFalseStart else { return }

        switch state {
        case .waiting:
            // False start
            hasFalseStart = true
            waitTask?.cancel()
            haptic.error()
            falseStartPlayer = index

            // Opponent(s) win automatically
            let opponents = (0..<config.playerMode.playerCount).filter { $0 != index }
            if let first = opponents.first {
                winnerIndex = first
            }
            state = .falseStart(index)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.state = .result
            }

        case .active:
            guard reactionTimes[index] == nil else { return } // Already tapped
            haptic.lightTap()

            let now = TimingService.now()
            reactionTimes[index] = TimingService.reactionMs(from: stimulusTime, to: now)

            // Check if all players have tapped
            if reactionTimes.allSatisfy({ $0 != nil }) {
                determineWinner()
            }

        default:
            break
        }
    }

    // MARK: - Private

    private func resetValues() {
        reactionTimes = Array(repeating: nil, count: config.playerMode.playerCount)
        winnerIndex = nil
        falseStartPlayer = nil
        hasFalseStart = false
        waitTask?.cancel()
    }

    private func runCountdown(from value: Int) {
        if value <= 0 {
            haptic.goImpact()
            beginWaitingPhase()
            return
        }

        state = .countdown(value)
        haptic.countdownBeat()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.runCountdown(from: value - 1)
        }
    }

    private func beginWaitingPhase() {
        state = .waiting

        let delay = Double.random(
            in: max(Constants.minWaitTime, Constants.minSafeWaitTime)...Constants.maxWaitTime
        )

        waitTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
            guard !Task.isCancelled else { return }
            self?.showStimulus()
        }
    }

    private func showStimulus() {
        stimulusTime = TimingService.now()
        state = .active
    }

    private func determineWinner() {
        // Winner = lowest reaction time
        var bestIndex = 0
        var bestTime = Int.max
        for (i, time) in reactionTimes.enumerated() {
            if let t = time, t < bestTime {
                bestTime = t
                bestIndex = i
            }
        }
        winnerIndex = bestIndex
        haptic.success()
        state = .result
    }

    deinit {
        waitTask?.cancel()
    }
}
