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

    private var stimulusTime: CFTimeInterval = 0
    private var waitTask: Task<Void, Never>?
    private let haptic = HapticService.shared
    private var lastActiveCell: Int = -1

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
        waitTask?.cancel()
        resetValues()
        state = .ready
    }

    func playerTapped(index: Int) {
        // In grid reaction, index = cell tapped (0-15)
        guard case .active = state else { return }
        guard index == activeCell else { return } // Must tap the lit cell

        haptic.lightTap()
        let now = TimingService.now()
        let ms = TimingService.reactionMs(from: stimulusTime, to: now)
        roundTimes.append(ms)
        activeCell = nil

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
        waitTask?.cancel()
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
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
        waitTask?.cancel()
    }
}
