import Foundation
import QuartzCore

/// Sound Reflex: React to audio beep (no visual cue). Screen stays dark.
/// Solo/2P/4P. Score = reaction time in ms.
@Observable
final class SoundReflexViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    var reactionTimes: [Int?]
    var winnerIndex: Int?
    var percentile: Int = 0

    private var stimulusTime: CFTimeInterval = 0
    private var waitTask: Task<Void, Never>?
    private let haptic = HapticService.shared
    private let sound = SoundService.shared
    private var hasFalseStart = false

    init(config: GameConfiguration) {
        self.config = config
        self.reactionTimes = Array(repeating: nil, count: config.playerMode.playerCount)
    }

    func startGame() {
        guard state == .ready || state == .result else { return }
        if case .falseStart = state { } else if state != .ready && state != .result { return }
        resetValues()
        sound.preloadBeep()
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
            hasFalseStart = true
            waitTask?.cancel()
            haptic.error()

            if config.playerMode == .solo {
                state = .falseStart(nil)
            } else {
                // Opponents win
                let opponents = (0..<config.playerMode.playerCount).filter { $0 != index }
                winnerIndex = opponents.first
                state = .falseStart(index)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.state = .result
            }

        case .active:
            guard reactionTimes[index] == nil else { return }
            haptic.lightTap()

            let now = TimingService.now()
            reactionTimes[index] = TimingService.reactionMs(from: stimulusTime, to: now)

            if config.playerMode == .solo {
                if let ms = reactionTimes[0] {
                    percentile = Constants.percentile(forReactionMs: ms)
                }
                haptic.success()
                state = .result
            } else if reactionTimes.allSatisfy({ $0 != nil }) {
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
        percentile = 0
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
        sound.playBeep() // Audio-only stimulus
        state = .active
    }

    private func determineWinner() {
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
