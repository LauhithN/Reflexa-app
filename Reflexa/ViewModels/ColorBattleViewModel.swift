import Foundation
import QuartzCore

/// Color Battle: Multi-round arena scoring mode.
/// Power rounds (every 3rd round) award bonus points. False start costs points.
@Observable
final class ColorBattleViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    // Scores per player
    var scores: [Int]
    var currentRound: Int = 1
    var roundWinner: Int? // Index of round winner (for display)
    var matchWinner: Int? // Overall match winner
    var lastRoundPointDelta: Int = 0
    var tieBreakUsed = false
    var tiedPlayers: [Int] = []

    var currentRoundPointValue: Int {
        currentRound.isMultiple(of: 3) ? 2 : 1
    }

    var isPowerRound: Bool {
        currentRoundPointValue > 1
    }

    private var stimulusTime: CFTimeInterval = 0
    private var waitTask: Task<Void, Never>?
    private var roundResetTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private let haptic = HapticService.shared
    private var roundHandled = false
    private var pausedState: GameState?

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
        countdownTask?.cancel()
        waitTask?.cancel()
        roundResetTask?.cancel()
        resetValues()
        state = .ready
    }

    func playerTapped(index: Int) {
        guard scores.indices.contains(index) else { return }
        guard !roundHandled else { return }

        switch state {
        case .waiting:
            // False start — player loses points (cannot go below zero)
            roundHandled = true
            waitTask?.cancel()
            haptic.error()

            scores[index] = max(scores[index] - 1, 0)
            lastRoundPointDelta = -1
            roundWinner = nil
            state = .falseStart(index)
            advanceOrFinish()

        case .active:
            // First valid tap wins the round
            roundHandled = true
            haptic.lightTap()

            let points = currentRoundPointValue
            scores[index] += points
            lastRoundPointDelta = points
            roundWinner = index
            state = .stopped
            advanceOrFinish()

        default:
            break
        }
    }

    func setPaused(_ paused: Bool) {
        if paused {
            guard pausedState == nil else { return }
            pausedState = state
            countdownTask?.cancel()
            waitTask?.cancel()
            roundResetTask?.cancel()
            return
        }

        guard let pausedState else { return }
        self.pausedState = nil

        switch pausedState {
        case .countdown(let value):
            runCountdown(from: value)
        case .waiting:
            beginWaitingPhase()
        case .stopped, .falseStart:
            scheduleRoundTransition()
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
        lastRoundPointDelta = 0
        tieBreakUsed = false
        tiedPlayers = []
        roundHandled = false
        countdownTask?.cancel()
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

        countdownTask?.cancel()
        countdownTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.runCountdown(from: value - 1)
        }
    }

    private func beginWaitingPhase() {
        roundHandled = false
        state = .waiting

        let delay = Double.random(
            in: max(1.4, Constants.minSafeWaitTime)...3.4
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
        scheduleRoundTransition()
    }

    private func scheduleRoundTransition() {
        // Check if all rounds played
        if currentRound >= config.roundCount {
            let maxScore = scores.max() ?? 0
            let leaders = scores.enumerated()
                .filter { $0.element == maxScore }
                .map(\.offset)

            tiedPlayers = leaders
            if leaders.count == 1 {
                matchWinner = leaders[0]
                tieBreakUsed = false
            } else {
                tieBreakUsed = true
                if let roundWinner, leaders.contains(roundWinner) {
                    matchWinner = roundWinner
                } else {
                    matchWinner = leaders.first
                }
            }

            haptic.success()

            roundResetTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(1.5))
                self?.state = .result
            }
            return
        }

        // Next round after brief delay
        roundResetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            self?.currentRound += 1
            self?.roundWinner = nil
            self?.runCountdown(from: 2)
        }
    }

    deinit {
        countdownTask?.cancel()
        waitTask?.cancel()
        roundResetTask?.cancel()
    }
}
