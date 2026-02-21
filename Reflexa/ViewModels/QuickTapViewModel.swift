import Foundation
import QuartzCore

/// Quick Tap: Tap as many times as possible in 10 seconds.
/// Score = tap count. Higher is better.
@Observable
final class QuickTapViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    var tapCount: Int = 0
    var timeRemaining: Double = Constants.quickTapDuration
    var isFinished: Bool = false

    var tapsPerSecond: Double = 0
    var bestTapsPerSecond: Double = 0
    var tapTimestamps: [CFTimeInterval] = []

    var speedTier: String {
        switch tapCount {
        case 80...: return "Inhuman"
        case 60..<80: return "Blazing"
        case 40..<60: return "Fast"
        default: return "Casual"
        }
    }

    private let timing = TimingService()
    private let haptic = HapticService.shared
    private var countdownTask: Task<Void, Never>?
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
        timing.stop()
        resetValues()
        state = .ready
    }

    func playerTapped(index: Int) {
        guard case .active = state else { return }
        haptic.lightTap()
        tapCount += 1
        tapTimestamps.append(CACurrentMediaTime())
    }

    func setPaused(_ paused: Bool) {
        if paused {
            guard pausedState == nil else { return }
            pausedState = state
            countdownTask?.cancel()
            timing.pause()
            return
        }

        guard let pausedState else { return }
        self.pausedState = nil

        switch pausedState {
        case .countdown(let value):
            runCountdown(from: value)
        case .active:
            timing.resume()
        default:
            break
        }
    }

    // MARK: - Private

    private func resetValues() {
        tapCount = 0
        timeRemaining = Constants.quickTapDuration
        isFinished = false
        tapsPerSecond = 0
        bestTapsPerSecond = 0
        tapTimestamps = []
        countdownTask?.cancel()
    }

    private func runCountdown(from value: Int) {
        if value <= 0 {
            haptic.goImpact()
            startTapping()
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

    private func startTapping() {
        state = .active

        timing.start { [weak self] elapsed in
            guard let self else { return }
            let remaining = Constants.quickTapDuration - elapsed
            if remaining <= 0 {
                self.timeRemaining = 0
                self.timing.stop()
                self.isFinished = true
                self.haptic.success()
                self.state = .result
            } else {
                self.timeRemaining = remaining
                self.updateTapsPerSecond()
            }
        }
    }

    private func updateTapsPerSecond() {
        let now = CACurrentMediaTime()
        let windowStart = now - 1.0
        let recentTaps = tapTimestamps.filter { $0 >= windowStart }
        tapsPerSecond = Double(recentTaps.count)
        if tapsPerSecond > bestTapsPerSecond {
            bestTapsPerSecond = tapsPerSecond
        }
    }

    deinit {
        countdownTask?.cancel()
        timing.stop()
    }
}
