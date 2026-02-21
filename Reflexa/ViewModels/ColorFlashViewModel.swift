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
    var isDecoyFlashVisible = false
    var decoyFlashesShown = 0

    private var stimulusTime: CFTimeInterval = 0
    private var waitTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private let haptic = HapticService.shared
    private var pausedState: GameState?

    init(config: GameConfiguration) {
        self.config = config
    }

    func startGame() {
        if case .ready = state { } else if case .result = state { } else if case .falseStart = state { } else { return }
        resetValues()
        state = .countdown(3)
        runCountdown(from: 3)
    }

    func resetGame() {
        countdownTask?.cancel()
        waitTask?.cancel()
        resetValues()
        state = .ready
    }

    func playerTapped(index: Int) {
        switch state {
        case .waiting:
            // False start — tapped before stimulus
            waitTask?.cancel()
            isDecoyFlashVisible = false
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

    func setPaused(_ paused: Bool) {
        if paused {
            guard pausedState == nil else { return }
            pausedState = state
            countdownTask?.cancel()
            waitTask?.cancel()
            return
        }

        guard let pausedState else { return }
        self.pausedState = nil

        switch pausedState {
        case .countdown(let value):
            runCountdown(from: value)
        case .waiting:
            beginWaitingPhase()
        default:
            break
        }
    }

    // MARK: - Private

    private func resetValues() {
        reactionTimeMs = 0
        percentile = 0
        isDecoyFlashVisible = false
        decoyFlashesShown = 0
        stimulusTime = 0
        countdownTask?.cancel()
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

        countdownTask?.cancel()
        countdownTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.runCountdown(from: value - 1)
        }
    }

    private func beginWaitingPhase() {
        state = .waiting
        isDecoyFlashVisible = false

        // Random delay between minWaitTime and maxWaitTime
        // Never less than minSafeWaitTime (1.5s)
        let delay = Double.random(
            in: max(Constants.minWaitTime, Constants.minSafeWaitTime)...Constants.maxWaitTime
        )
        let decoyCount = Int.random(in: 1...2)
        let latestDecoyMoment = max(delay - 0.45, 0.35)
        let decoyMoments: [Double] = (0..<decoyCount).map { _ in
            Double.random(in: 0.35...latestDecoyMoment)
        }
        .sorted()

        waitTask = Task { @MainActor [weak self] in
            guard let self else { return }

            var elapsed = 0.0

            for moment in decoyMoments {
                let segment = max(moment - elapsed, 0)
                if segment > 0 {
                    try? await Task.sleep(for: .milliseconds(Int(segment * 1000)))
                }
                guard !Task.isCancelled else { return }
                guard self.state == .waiting else { return }
                await self.triggerDecoyFlash()
                elapsed = moment + 0.14
            }

            let remaining = max(delay - elapsed, 0)
            if remaining > 0 {
                try? await Task.sleep(for: .milliseconds(Int(remaining * 1000)))
            }
            guard !Task.isCancelled else { return }
            self.showStimulus()
        }
    }

    @MainActor
    private func triggerDecoyFlash() async {
        isDecoyFlashVisible = true
        decoyFlashesShown += 1
        haptic.lightTap()
        try? await Task.sleep(for: .milliseconds(120))
        guard state == .waiting else { return }
        isDecoyFlashVisible = false
    }

    private func showStimulus() {
        isDecoyFlashVisible = false
        stimulusTime = TimingService.now()
        state = .active
        haptic.goImpact()
    }

    deinit {
        countdownTask?.cancel()
        waitTask?.cancel()
    }
}
