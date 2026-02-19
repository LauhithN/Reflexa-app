import Foundation
import QuartzCore

/// Grid Reaction: 4x4 grid, one square lights up, tap it.
/// 10 rounds, score = average reaction time.
@Observable
final class GridReactionViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    let gridSize = 4
    var activeCell: Int? // 0-15, which cell is lit
    var currentRound: Int = 0
    var roundTimes: [Int] = [] // ms per round
    var averageTimeMs: Int = 0
    var percentile: Int = 0

    var lastTapCorrect: Bool?
    var lastTapCellIndex: Int?
    var wrongTapCount: Int = 0
    var fastestRoundMs: Int?
    var slowestRoundMs: Int?

    private var stimulusTime: CFTimeInterval = 0
    private var waitTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private let haptic = HapticService.shared
    private var lastActiveCell: Int = -1

    var speedTier: String {
        switch averageTimeMs {
        case ..<300: return "Lightning Reflexes"
        case 300..<450: return "Sharp Eyes"
        case 450..<600: return "Good Start"
        default: return "Keep Practicing"
        }
    }

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
        waitTask?.cancel()
        feedbackTask?.cancel()
        resetValues()
        state = .ready
    }

    func playerTapped(index: Int) {
        // In grid reaction, index = cell tapped (0-15)
        guard (0..<(gridSize * gridSize)).contains(index) else { return }
        guard case .active = state else { return }

        if index == activeCell {
            // Correct tap
            haptic.lightTap()
            let now = TimingService.now()
            let ms = TimingService.reactionMs(from: stimulusTime, to: now)
            roundTimes.append(ms)

            // Update fastest/slowest
            if fastestRoundMs == nil || ms < fastestRoundMs! {
                fastestRoundMs = ms
            }
            if slowestRoundMs == nil || ms > slowestRoundMs! {
                slowestRoundMs = ms
            }

            lastTapCorrect = true
            lastTapCellIndex = index
            activeCell = nil

            clearFeedbackAfterDelay()

            if roundTimes.count >= Constants.gridReactionRounds {
                // All rounds complete
                averageTimeMs = roundTimes.reduce(0, +) / roundTimes.count
                percentile = Constants.percentile(forReactionMs: averageTimeMs)
                haptic.success()
                state = .result
            } else {
                // Brief pause then next round
                currentRound = roundTimes.count + 1
                state = .waiting

                waitTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .milliseconds(Int.random(in: 800...1500)))
                    guard !Task.isCancelled else { return }
                    self?.lightUpRandomCell()
                }
            }
        } else {
            // Wrong tap
            haptic.error()
            wrongTapCount += 1
            lastTapCorrect = false
            lastTapCellIndex = index
            clearFeedbackAfterDelay()
        }
    }

    /// Called from the grid view — tap on specific cell
    func cellTapped(_ cellIndex: Int) {
        playerTapped(index: cellIndex)
    }

    // MARK: - Private

    private func resetValues() {
        activeCell = nil
        currentRound = 0
        roundTimes = []
        averageTimeMs = 0
        percentile = 0
        lastActiveCell = -1
        lastTapCorrect = nil
        lastTapCellIndex = nil
        wrongTapCount = 0
        fastestRoundMs = nil
        slowestRoundMs = nil
        countdownTask?.cancel()
        waitTask?.cancel()
        feedbackTask?.cancel()
    }

    private func clearFeedbackAfterDelay() {
        feedbackTask?.cancel()
        feedbackTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.lastTapCorrect = nil
            self?.lastTapCellIndex = nil
        }
    }

    private func runCountdown(from value: Int) {
        if value <= 0 {
            haptic.goImpact()
            currentRound = 1
            beginFirstRound()
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

    private func beginFirstRound() {
        state = .waiting
        waitTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(Int.random(in: 500...1200)))
            guard !Task.isCancelled else { return }
            self?.lightUpRandomCell()
        }
    }

    private func lightUpRandomCell() {
        // Pick a random cell, avoiding the same cell twice in a row
        var cell: Int
        repeat {
            cell = Int.random(in: 0..<(gridSize * gridSize))
        } while cell == lastActiveCell

        lastActiveCell = cell
        activeCell = cell
        stimulusTime = TimingService.now()
        state = .active
    }

    deinit {
        countdownTask?.cancel()
        waitTask?.cancel()
        feedbackTask?.cancel()
    }
}
