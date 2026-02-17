import Foundation
import SwiftData
import QuartzCore

/// Daily Challenge: One attempt per day (midnight reset). Color flash style.
/// Tracks all-time best.
@Observable
final class DailyChallengeViewModel: GameViewModelProtocol {
    let config: GameConfiguration
    var state: GameState = .ready

    var reactionTimeMs: Int = 0
    var percentile: Int = 0
    var hasAttemptedToday: Bool = false
    var todayScore: Int? // nil if not attempted or false start
    var allTimeBest: Int?
    var countdownToNext: String = ""

    private var stimulusTime: CFTimeInterval = 0
    private var waitTask: Task<Void, Never>?
    private let haptic = HapticService.shared
    private var modelContext: ModelContext?

    init(config: GameConfiguration = GameConfiguration(gameType: .dailyChallenge, playerMode: .solo)) {
        self.config = config
    }

    /// Call after view appears to load today's status
    func loadStatus(modelContext: ModelContext) {
        self.modelContext = modelContext
        let todayKey = Date().dailyKey

        let descriptor = FetchDescriptor<DailyChallenge>(
            predicate: #Predicate { $0.dateKey == todayKey }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            hasAttemptedToday = existing.attempted
            todayScore = existing.reactionTimeMs
        }

        // Load all-time best
        let allDescriptor = FetchDescriptor<DailyChallenge>(
            sortBy: [SortDescriptor(\.reactionTimeMs)]
        )
        if let results = try? modelContext.fetch(allDescriptor) {
            allTimeBest = results.compactMap(\.reactionTimeMs).min()
        }

        countdownToNext = Date().countdownToMidnight
    }

    func startGame() {
        guard !hasAttemptedToday else { return }
        guard state == .ready else { return }
        state = .countdown(3)
        runCountdown(from: 3)
    }

    func resetGame() {
        waitTask?.cancel()
        state = .ready
    }

    func playerTapped(index: Int) {
        switch state {
        case .waiting:
            // False start — attempt used, no score
            waitTask?.cancel()
            haptic.error()
            recordResult(reactionTimeMs: nil)
            state = .falseStart(nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.state = .result
            }

        case .active:
            let now = TimingService.now()
            reactionTimeMs = TimingService.reactionMs(from: stimulusTime, to: now)
            percentile = Constants.percentile(forReactionMs: reactionTimeMs)
            haptic.success()
            GameCenterService.shared.submitScore(reactionTimeMs, for: .dailyChallenge)
            recordResult(reactionTimeMs: reactionTimeMs)
            state = .result

        default:
            break
        }
    }

    // MARK: - Private

    private func recordResult(reactionTimeMs: Int?) {
        guard let modelContext else { return }

        let todayKey = Date().dailyKey
        let descriptor = FetchDescriptor<DailyChallenge>(
            predicate: #Predicate { $0.dateKey == todayKey }
        )

        let challenge: DailyChallenge
        if let existing = try? modelContext.fetch(descriptor).first {
            challenge = existing
        } else {
            challenge = DailyChallenge(dateKey: todayKey)
            modelContext.insert(challenge)
        }

        challenge.recordResult(reactionTimeMs: reactionTimeMs)
        hasAttemptedToday = true
        todayScore = reactionTimeMs

        if let ms = reactionTimeMs {
            if let current = allTimeBest {
                allTimeBest = min(current, ms)
            } else {
                allTimeBest = ms
            }
        }

        try? modelContext.save()
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
        state = .active
    }

    deinit {
        waitTask?.cancel()
    }
}
