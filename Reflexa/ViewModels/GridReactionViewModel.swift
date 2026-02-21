import Foundation
import QuartzCore
import Combine

/// Grid Reaction: 4x4 grid, one square lights up, tap it.
/// 10 rounds, score = average reaction time.
final class GridReactionViewModel: ObservableObject, GameViewModelProtocol {
    let config: GameConfiguration
    @Published var state: GameState = .ready

    let gridSize = 4
    @Published var activeCell: Int? // 0-15, which cell is lit
    @Published var currentRound: Int = 0
    @Published var roundTimes: [Int] = [] // ms per round
    @Published var averageTimeMs: Int = 0
    @Published var percentile: Int = 0

    @Published var lastTapCorrect: Bool?
    @Published var lastTapCellIndex: Int?
    @Published var wrongTapCount: Int = 0
    @Published var fastestRoundMs: Int?
    @Published var slowestRoundMs: Int?

    private var stimulusTime: CFTimeInterval = 0
    private var waitTask: Task<Void, Never>?
    private var feedbackTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private let haptic = HapticService.shared
    private var lastActiveCell: Int = -1
    private var pausedState: GameState?

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
                scheduleWaitingForNextStimulus()
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

    func setPaused(_ paused: Bool) {
        if paused {
            guard pausedState == nil else { return }
            pausedState = state
            countdownTask?.cancel()
            waitTask?.cancel()
            feedbackTask?.cancel()
            return
        }

        guard let pausedState else { return }
        self.pausedState = nil

        switch pausedState {
        case .countdown(let value):
            runCountdown(from: value)
        case .waiting:
            if roundTimes.isEmpty {
                beginFirstRound()
            } else {
                scheduleWaitingForNextStimulus()
            }
        default:
            break
        }
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
        scheduleWaitingForNextStimulus(delayRange: 500...1200)
    }

    private func scheduleWaitingForNextStimulus(delayRange: ClosedRange<Int> = 800...1500) {
        waitTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(Int.random(in: delayRange)))
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
