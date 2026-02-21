import Foundation
import QuartzCore
import Combine

/// Charge & Release: Wait for signal, hold to charge, release near target.
/// Winner = lowest offset from target. False start loses immediately.
final class ReactionDuelViewModel: ObservableObject, GameViewModelProtocol {
    let config: GameConfiguration
    @Published var state: GameState = .ready

    let targetCharge: Double = 75
    let perfectWindow: ClosedRange<Double> = 72...78

    @Published var chargeValues: [Double] // live charge 0...100
    @Published var lockedCharges: [Double?] // final released charge
    @Published var roundScores: [Double?] // abs offset from target (lower is better)
    @Published var reactionTimes: [Int?] // ms to initial press after signal
    @Published var chargingStates: [Bool] // true while player is holding
    @Published var winnerIndex: Int?
    @Published var falseStartPlayer: Int?

    private let haptic = HapticService.shared
    private let timing = TimingService()
    private var signalTime: CFTimeInterval = 0
    private var chargeStartTimes: [CFTimeInterval?]
    private var waitTask: Task<Void, Never>?
    private var delayedResultTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var hasFalseStart = false
    private var pausedState: GameState?

    private let chargeRatePerSecond = 68.0
    private let overchargePenalty = 12.0

    init(config: GameConfiguration) {
        self.config = config
        let count = config.playerMode.playerCount
        self.chargeValues = Array(repeating: 0, count: count)
        self.lockedCharges = Array(repeating: nil, count: count)
        self.roundScores = Array(repeating: nil, count: count)
        self.reactionTimes = Array(repeating: nil, count: count)
        self.chargingStates = Array(repeating: false, count: count)
        self.chargeStartTimes = Array(repeating: nil, count: count)
    }

    func startGame() {
        switch state {
        case .ready, .result, .falseStart:
            timing.stop()
            countdownTask?.cancel()
            waitTask?.cancel()
            delayedResultTask?.cancel()
            resetValues()
            state = .countdown(3)
            runCountdown(from: 3)
        default:
            return
        }
    }

    func resetGame() {
        countdownTask?.cancel()
        timing.stop()
        waitTask?.cancel()
        delayedResultTask?.cancel()
        resetValues()
        state = .ready
    }

    /// Protocol requirement; charge mode uses press begin/end instead of taps.
    func playerTapped(index: Int) {}

    // MARK: - Charge Input

    func playerPressBegan(index: Int) {
        guard chargeValues.indices.contains(index) else { return }
        guard !hasFalseStart else { return }

        switch state {
        case .waiting:
            handleFalseStart(by: index)

        case .active:
            guard winnerIndex == nil else { return }
            guard lockedCharges[index] == nil else { return }
            guard !chargingStates[index] else { return }

            chargingStates[index] = true
            let start = TimingService.now()
            chargeStartTimes[index] = start

            if reactionTimes[index] == nil {
                reactionTimes[index] = TimingService.reactionMs(from: signalTime, to: start)
            }

            haptic.lightTap()

        default:
            break
        }
    }

    func playerPressEnded(index: Int) {
        guard chargeValues.indices.contains(index) else { return }
        guard !hasFalseStart else { return }
        guard case .active = state else { return }
        finalizeCharge(for: index, manualRelease: true)
    }

    func setPaused(_ paused: Bool) {
        if paused {
            guard pausedState == nil else { return }
            pausedState = state
            countdownTask?.cancel()
            waitTask?.cancel()
            delayedResultTask?.cancel()
            timing.pause()
            return
        }

        guard let pausedState else { return }
        self.pausedState = nil

        switch pausedState {
        case .countdown(let value):
            runCountdown(from: value)
        case .waiting:
            beginWaitingPhase()
        case .active:
            timing.resume()
        default:
            break
        }
    }

    // MARK: - Private

    private func resetValues() {
        let count = config.playerMode.playerCount
        chargeValues = Array(repeating: 0, count: count)
        lockedCharges = Array(repeating: nil, count: count)
        roundScores = Array(repeating: nil, count: count)
        reactionTimes = Array(repeating: nil, count: count)
        chargingStates = Array(repeating: false, count: count)
        chargeStartTimes = Array(repeating: nil, count: count)
        winnerIndex = nil
        falseStartPlayer = nil
        hasFalseStart = false
        signalTime = 0
        countdownTask?.cancel()
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

        let delay = Double.random(
            in: max(1.3, Constants.minSafeWaitTime)...3.2
        )

        waitTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
            guard !Task.isCancelled else { return }
            self?.showStimulus()
        }
    }

    private func showStimulus() {
        signalTime = TimingService.now()
        state = .active
        haptic.goImpact()
        timing.start { [weak self] _ in
            self?.tickChargeFrame()
        }
    }

    private func tickChargeFrame() {
        guard case .active = state else { return }

        let now = TimingService.now()
        var autoFinalizePlayers: [Int] = []

        for index in chargeValues.indices where chargingStates[index] {
            guard let start = chargeStartTimes[index] else { continue }
            let elapsed = now - start
            let charge = min(100, max(chargeValues[index], elapsed * chargeRatePerSecond))
            chargeValues[index] = charge

            if charge >= 100 {
                autoFinalizePlayers.append(index)
            }
        }

        for index in autoFinalizePlayers {
            finalizeCharge(for: index, manualRelease: false)
        }
    }

    private func finalizeCharge(for index: Int, manualRelease: Bool) {
        guard chargingStates.indices.contains(index) else { return }
        guard chargingStates[index] else { return }
        guard lockedCharges[index] == nil else { return }

        chargingStates[index] = false
        chargeStartTimes[index] = nil

        let finalCharge = min(max(chargeValues[index], 0), 100)
        chargeValues[index] = finalCharge
        lockedCharges[index] = finalCharge

        let offset = abs(finalCharge - targetCharge)
        if manualRelease {
            roundScores[index] = offset
            haptic.lightTap()
        } else {
            roundScores[index] = offset + overchargePenalty
            haptic.warning()
        }

        if lockedCharges.allSatisfy({ $0 != nil }) {
            determineWinner()
        }
    }

    private func determineWinner() {
        timing.stop()

        let ranking = (0..<config.playerMode.playerCount).sorted { lhs, rhs in
            let lhsScore = roundScores[lhs] ?? Double.greatestFiniteMagnitude
            let rhsScore = roundScores[rhs] ?? Double.greatestFiniteMagnitude
            if lhsScore == rhsScore {
                let lhsReaction = reactionTimes[lhs] ?? Int.max
                let rhsReaction = reactionTimes[rhs] ?? Int.max
                return lhsReaction < rhsReaction
            }
            return lhsScore < rhsScore
        }

        winnerIndex = ranking.first
        haptic.success()
        state = .result
    }

    private func handleFalseStart(by index: Int) {
        guard !hasFalseStart else { return }
        hasFalseStart = true
        waitTask?.cancel()

        falseStartPlayer = index
        winnerIndex = (0..<config.playerMode.playerCount).first(where: { $0 != index })
        haptic.error()
        state = .falseStart(index)

        delayedResultTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.3))
            guard !Task.isCancelled else { return }
            self?.state = .result
        }
    }

    deinit {
        countdownTask?.cancel()
        timing.stop()
        waitTask?.cancel()
        delayedResultTask?.cancel()
    }
}
