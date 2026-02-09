import Foundation
import QuartzCore

/// Color Battle: Best of N rounds. Screen changes color after random delay.
/// First to tap wins round. False start = opponent gets point.
@Observable
final class ColorBattleViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    // Scores per player
    var scores: [Int]
    var currentRound: Int = 1
    var roundWinner: Int? // Index of round winner (for display)
    var matchWinner: Int? // Overall match winner

    private var stimulusTime: CFTimeInterval = 0
    private var waitTask: Task<Void, Never>?
    private var roundResetTask: Task<Void, Never>?
    private let haptic = HapticService.shared
    private var roundHandled = false

    init(config: GameConfiguration) {
        self.config = config
        self.scores = Array(repeating: 0, count: config.playerMode.playerCount)
    }

    func startGame() {
        guard state == .ready || state == .result else { return }
        resetValues()
        state = .countdown(3)
        runCountdown(from: 3)
    }

    func resetGame() {
        waitTask?.cancel()
        roundResetTask?.cancel()
        resetValues()
        state = .ready
    }

    func playerTapped(index: Int) {
        guard !roundHandled else { return }

        switch state {
        case .waiting:
            // False start — all other players get a point
            roundHandled = true
            waitTask?.cancel()
            haptic.error()

            for i in 0..<scores.count where i != index {
                scores[i] += 1
            }
            roundWinner = nil
            state = .falseStart(index)
            advanceOrFinish()

        case .active:
            // First valid tap wins the round
            roundHandled = true
            haptic.lightTap()

            scores[index] += 1
            roundWinner = index
            state = .stopped
            advanceOrFinish()

        default:
            break
        }
    }

    // MARK: - Private

    private func resetValues() {
        scores = Array(repeating: 0, count: config.playerMode.playerCount)
        currentRound = 1
        roundWinner = nil
        matchWinner = nil
        roundHandled = false
        waitTask?.cancel()
        roundResetTask?.cancel()
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
        roundHandled = false
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

    private func advanceOrFinish() {
        // Check if anyone has won the majority
        if let winner = scores.enumerated().first(where: { $0.element >= config.majorityNeeded }) {
            matchWinner = winner.offset
            haptic.success()

            roundResetTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(2))
                self?.state = .result
            }
            return
        }

        // Check if all rounds played
        if currentRound >= config.roundCount {
            // Find winner by highest score
            matchWinner = scores.enumerated().max(by: { $0.element < $1.element })?.offset
            haptic.success()

            roundResetTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(2))
                self?.state = .result
            }
            return
        }

        // Next round after brief delay
        roundResetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self?.currentRound += 1
            self?.roundWinner = nil
            self?.runCountdown(from: 3)
        }
    }

    deinit {
        waitTask?.cancel()
        roundResetTask?.cancel()
    }
}
