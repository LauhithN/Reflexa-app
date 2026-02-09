import Foundation
import QuartzCore

/// Color Flash: Screen turns RED after random 2-5s delay. Tap ASAP.
/// Score = reaction time in ms. False start if tap during wait.
@Observable
final class ColorFlashViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    var reactionTimeMs: Int = 0
    var percentile: Int = 0

    private var stimulusTime: CFTimeInterval = 0
    private var waitTask: Task<Void, Never>?
    private let haptic = HapticService.shared

    init(config: GameConfiguration) {
        self.config = config
    }

    func startGame() {
        guard state == .ready || state == .result || state is GameState else { return }
        if case .ready = state { } else if case .result = state { } else if case .falseStart = state { } else { return }
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
        switch state {
        case .waiting:
            // False start — tapped before stimulus
            waitTask?.cancel()
            haptic.error()
            state = .falseStart(nil)

        case .active:
            // Valid tap — measure reaction time
            let now = TimingService.now()
            reactionTimeMs = TimingService.reactionMs(from: stimulusTime, to: now)
            percentile = Constants.percentile(forReactionMs: reactionTimeMs)
            haptic.success()
            state = .result

        default:
            break
        }
    }

    // MARK: - Private

    private func resetValues() {
        reactionTimeMs = 0
        percentile = 0
        stimulusTime = 0
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

        // Random delay between minWaitTime and maxWaitTime
        // Never less than minSafeWaitTime (1.5s)
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
        haptic.goImpact()
    }

    deinit {
        waitTask?.cancel()
    }
}
