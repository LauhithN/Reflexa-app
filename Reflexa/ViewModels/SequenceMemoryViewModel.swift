import Foundation

/// Sequence Memory: Watch a sequence flash on a 2x2 grid, then repeat it.
/// Each level adds one step. Wrong tap = game over. Score = highest level completed.
@Observable
final class SequenceMemoryViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    var level: Int = 0
    var sequence: [Int] = []
    var highlightedCell: Int? = nil
    var inputProgress: Int = 0
    var isShowingSequence: Bool = false
    var wrongTapIndex: Int? = nil
    var correctTapIndex: Int? = nil
    var finalLevel: Int = 0

    var performanceTier: String {
        switch finalLevel {
        case 15...: return "Legendary"
        case 10..<15: return "Exceptional"
        case 7..<10: return "Solid"
        case 4..<7: return "Getting There"
        default: return "Keep Practicing"
        }
    }

    private let haptic = HapticService.shared
    private var playbackTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var resultTransitionTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?
    private var pausedState: GameState?

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
        countdownTask?.cancel()
        resultTransitionTask?.cancel()
        feedbackTask?.cancel()
        playbackTask?.cancel()
        resetValues()
        state = .ready
    }

    func playerTapped(index: Int) {
        guard case .active = state, !isShowingSequence else { return }
        guard index >= 0 && index < 4 else { return }
        guard sequence.indices.contains(inputProgress) else { return }

        if sequence[inputProgress] == index {
            // Correct tap
            haptic.lightTap()
            correctTapIndex = index
            inputProgress += 1

            clearFeedback(after: 0.2)

            if inputProgress >= sequence.count {
                // Level complete — advance
                beginNextLevel()
            }
        } else {
            // Wrong tap — game over
            haptic.error()
            wrongTapIndex = index
            finalLevel = max(level - 1, 0)
            playbackTask?.cancel()
            resultTransitionTask?.cancel()
            resultTransitionTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                self?.wrongTapIndex = nil
                self?.state = .result
            }
        }
    }

    func setPaused(_ paused: Bool) {
        if paused {
            guard pausedState == nil else { return }
            pausedState = state
            countdownTask?.cancel()
            resultTransitionTask?.cancel()
            feedbackTask?.cancel()
            playbackTask?.cancel()
            return
        }

        guard let pausedState else { return }
        self.pausedState = nil

        switch pausedState {
        case .countdown(let value):
            runCountdown(from: value)
        case .active:
            if isShowingSequence {
                playSequence()
            }
        default:
            break
        }
    }

    // MARK: - Private

    private func resetValues() {
        level = 0
        sequence = []
        highlightedCell = nil
        inputProgress = 0
        isShowingSequence = false
        wrongTapIndex = nil
        correctTapIndex = nil
        finalLevel = 0
        countdownTask?.cancel()
        resultTransitionTask?.cancel()
        feedbackTask?.cancel()
        playbackTask?.cancel()
    }

    private func runCountdown(from value: Int) {
        if value <= 0 {
            haptic.goImpact()
            beginNextLevel()
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

    private func beginNextLevel() {
        level += 1
        inputProgress = 0
        sequence.append(Int.random(in: 0..<4))
        state = .active
        playSequence()
    }

    private func playSequence() {
        isShowingSequence = true
        highlightedCell = nil

        playbackTask?.cancel()
        playbackTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // Brief pause before starting playback
            try? await Task.sleep(for: .milliseconds(400))

            for step in self.sequence {
                guard !Task.isCancelled else { return }

                self.highlightedCell = step
                try? await Task.sleep(for: .milliseconds(
                    Int(Constants.sequenceMemoryFlashDuration * 1000)
                ))

                guard !Task.isCancelled else { return }
                self.highlightedCell = nil
                try? await Task.sleep(for: .milliseconds(
                    Int(Constants.sequenceMemoryFlashGap * 1000)
                ))
            }

            guard !Task.isCancelled else { return }
            self.isShowingSequence = false
        }
    }

    private func clearFeedback(after delay: Double) {
        feedbackTask?.cancel()
        feedbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
            guard !Task.isCancelled else { return }
            self?.correctTapIndex = nil
        }
    }

    deinit {
        countdownTask?.cancel()
        resultTransitionTask?.cancel()
        feedbackTask?.cancel()
        playbackTask?.cancel()
    }
}
