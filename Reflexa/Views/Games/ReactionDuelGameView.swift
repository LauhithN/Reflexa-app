import SwiftUI

struct ReactionDuelGameView: View {
    let config: GameConfiguration

    @Environment(\.dismiss) private var dismiss

    @State private var currentRound = 1
    @State private var scores: [Int] = []
    @State private var penalties: [Int] = []
    @State private var reactionTimes: [Int?] = []
    @State private var matchReactionSums: [Int] = []
    @State private var matchReactionCounts: [Int] = []
    @State private var earlyPlayers: Set<Int> = []

    @State private var activePlayerIndex = 0
    @State private var triggerFired = false
    @State private var triggerDate = Date()
    @State private var roundAnnouncement: String?
    @State private var showPassDevice = false
    @State private var showResult = false
    @State private var countdownValue: Int? = nil

    @State private var roundTask: Task<Void, Never>?
    @State private var waitTask: Task<Void, Never>?

    private var playerCount: Int { config.playerMode.playerCount }
    private var totalRounds: Int { Constants.reactionDuelRounds }
    private var compactLayout: Bool { playerCount == 4 }

    var body: some View {
        ZStack {
            AmbientBackground()

            if config.playerMode == .solo {
                unsupportedView
            } else if config.isTurnBased {
                turnBasedPlayfield
            } else {
                simultaneousPlayfield
            }

            if let countdownValue {
                CountdownOverlay(value: countdownValue)
            }

            if showResult {
                ResultScreen(
                    scores: resultPayload,
                    scoreLabel: "round wins",
                    gameType: .reactionDuel,
                    onPlayAgain: restart,
                    onHome: { dismiss() }
                )
            }
        }
        .onAppear {
            restart()
        }
        .onDisappear {
            waitTask?.cancel()
            roundTask?.cancel()
        }
        .gameScaffold(title: "Reaction Duel", gameType: .reactionDuel) {
            dismiss()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    private var unsupportedView: some View {
        VStack(spacing: 16) {
            Text("Reaction Duel is multiplayer only")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)

            Text("Choose 2 Players or 4 Players from setup.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Button("Back") { dismiss() }
                .buttonStyle(PrimaryCTAButtonStyle())
                .padding(.horizontal, 24)
        }
    }

    private var simultaneousPlayfield: some View {
        ZStack {
            MultiplayerArenaLayout(playerCount: playerCount, topInset: 110, bottomInset: 18) { playerIndex in
                reactionPanel(for: playerIndex, compact: compactLayout)
            }

            VStack(spacing: 10) {
                PlayerScoreboard(players: livePlayerResults)
                Text("Round \(currentRound) / \(totalRounds)")
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)

                if let roundAnnouncement {
                    roundAnnouncementPill(roundAnnouncement)
                }
            }
            .padding(.top, 14)
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity, alignment: .top)

            triggerCard
                .padding(.top, compactLayout ? 22 : 12)
                .allowsHitTesting(false)
        }
    }

    private var turnBasedPlayfield: some View {
        TurnBasedStageContainer(
            roundTitle: "Round \(currentRound) / \(totalRounds)",
            subtitle: turnBasedSubtitle,
            activePlayerName: config.activePlayerNames[activePlayerIndex],
            activePlayerColor: Color.playerColor(for: activePlayerIndex),
            players: livePlayerResults,
            activePlayerIndex: activePlayerIndex,
            showPassDevice: showPassDevice,
            onReady: startTurnBasedTurn
        ) {
            reactionTurnContent(for: activePlayerIndex)
        }
    }

    private var triggerCard: some View {
        GlassCard(cornerRadius: compactLayout ? 24 : 28) {
            VStack(spacing: compactLayout ? 8 : 10) {
                PulseOrb(
                    color: triggerFired ? .accentAmber : .accentPrimary,
                    size: compactLayout ? 78 : 112,
                    pulseScale: 1.16,
                    pulseDuration: 1.2
                )

                Text(triggerFired ? "TAP!" : "WAIT...")
                    .font(compactLayout ? .sectionTitle : .resultTitle)
                    .foregroundStyle(triggerFired ? Color.accentAmber : Color.textPrimary)

                Text(triggerFired ? "fastest clean tap wins" : "false starts add 500ms")
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: compactLayout ? 176 : 228)
        }
    }

    private func reactionPanel(for playerIndex: Int, compact: Bool) -> some View {
        let name = config.activePlayerNames[playerIndex]
        let color = Color.playerColor(for: playerIndex)

        return MultiplayerPlayerPanel(
            name: name,
            accentColor: color,
            subtitle: compact ? nil : "Reaction lane",
            compact: compact,
            headerTrailing: {
                Text("W \(scores[safe: playerIndex] ?? 0)")
                    .font(.monoSmall)
                    .foregroundStyle(color)
            },
            content: {
                VStack(spacing: compact ? 8 : 12) {
                    reactionPulse(
                        color: color,
                        state: zoneState(for: playerIndex),
                        compact: compact
                    )

                    Text(zoneStatus(playerIndex: playerIndex))
                        .font(compact ? .sectionTitle : .resultTitle)
                        .foregroundStyle(triggerFired ? Color.accentAmber : Color.textPrimary)
                        .lineLimit(1)

                    if let reaction = reactionTimes[safe: playerIndex] ?? nil {
                        Text("\(reaction)ms")
                            .font(.monoSmall)
                            .foregroundStyle(Color.textPrimary)
                            .monospacedDigit()
                    } else {
                        Text(triggerFired ? "Tap your zone now" : "Hold for GO")
                            .font(.monoSmall)
                            .foregroundStyle(Color.textSecondary)
                    }

                    if earlyPlayers.contains(playerIndex), reactionTimes[safe: playerIndex] == nil {
                        Text("False start +500ms")
                            .font(.monoSmall)
                            .foregroundStyle(Color.destructive)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        )
        .contentShape(RoundedRectangle(cornerRadius: compact ? 22 : 28, style: .continuous))
        .onTapGesture {
            handleTap(playerIndex)
        }
        .accessibilityLabel("\(name) zone")
    }

    private func reactionTurnContent(for playerIndex: Int) -> some View {
        let color = Color.playerColor(for: playerIndex)

        return VStack(spacing: 16) {
            Spacer(minLength: 8)

            reactionPulse(
                color: color,
                state: zoneState(for: playerIndex),
                compact: false,
                size: 136
            )

            Text(zoneStatus(playerIndex: playerIndex))
                .font(.resultTitle)
                .foregroundStyle(triggerFired ? Color.accentAmber : Color.textPrimary)

            if let reaction = reactionTimes[safe: playerIndex] ?? nil {
                Text("\(reaction)ms")
                    .font(.monoLarge)
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
            } else {
                Text(triggerFired ? "Tap the arena as soon as GO lands." : "False starts add 500ms.")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if earlyPlayers.contains(playerIndex), reactionTimes[safe: playerIndex] == nil {
                Text("False start +500ms")
                    .font(.monoSmall)
                    .foregroundStyle(Color.destructive)
            }

            Spacer()

            Button {
                handleTap(playerIndex)
            } label: {
                Text(triggerFired ? "Tap Now" : "Ready Finger")
            }
            .buttonStyle(PrimaryCTAButtonStyle(tint: triggerFired ? .accentAmber : color))
            .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap(playerIndex)
        }
    }

    private func reactionPulse(
        color: Color,
        state: ReactionZoneState,
        compact: Bool,
        size: CGFloat? = nil
    ) -> some View {
        let orbSize = size ?? (compact ? 58 : 74)

        return ZStack {
            Circle()
                .fill(color.opacity(state == .locked ? 0.22 : 0.12))
                .frame(width: orbSize + (compact ? 22 : 30), height: orbSize + (compact ? 22 : 30))

            Circle()
                .stroke(color.opacity(state == .armed ? 0.82 : 0.46), lineWidth: compact ? 2 : 3)
                .frame(width: orbSize, height: orbSize)

            Circle()
                .fill(state == .armed ? Color.accentAmber : color.opacity(0.4))
                .frame(width: orbSize * 0.58, height: orbSize * 0.58)
                .shadow(color: (state == .armed ? Color.accentAmber : color).opacity(0.5), radius: compact ? 8 : 12)
        }
    }

    private func roundAnnouncementPill(_ text: String) -> some View {
        Text(text)
            .font(.monoSmall)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            .clipShape(Capsule())
    }

    private var turnBasedSubtitle: String {
        if let roundAnnouncement, showPassDevice {
            return roundAnnouncement
        }
        return triggerFired ? "Tap as soon as GO appears." : "Each player gets one reaction run per round."
    }

    private var livePlayerResults: [PlayerResult] {
        (0..<playerCount).map { index in
            PlayerResult(
                name: config.activePlayerNames[index],
                color: Color.playerColor(for: index),
                score: Double(scores[safe: index] ?? 0),
                isWinner: false,
                isNewBest: false,
                rank: index + 1
            )
        }
    }

    private var resultPayload: [PlayerResult] {
        let ranking = (0..<playerCount).sorted { lhs, rhs in
            if scores[lhs] == scores[rhs] {
                return averageReaction(for: lhs) < averageReaction(for: rhs)
            }
            return scores[lhs] > scores[rhs]
        }

        return ranking.enumerated().map { order, index in
            PlayerResult(
                name: config.activePlayerNames[index],
                color: Color.playerColor(for: index),
                score: Double(scores[index]),
                isWinner: order == 0,
                isNewBest: false,
                rank: order + 1
            )
        }
    }

    private func restart() {
        guard config.playerMode != .solo else { return }

        currentRound = 1
        activePlayerIndex = 0
        scores = Array(repeating: 0, count: playerCount)
        penalties = Array(repeating: 0, count: playerCount)
        reactionTimes = Array(repeating: nil, count: playerCount)
        matchReactionSums = Array(repeating: 0, count: playerCount)
        matchReactionCounts = Array(repeating: 0, count: playerCount)
        earlyPlayers = []
        triggerFired = false
        roundAnnouncement = nil
        showResult = false
        showPassDevice = false
        countdownValue = nil

        waitTask?.cancel()
        roundTask?.cancel()

        if config.isTurnBased {
            showPassDevice = true
        } else {
            startSimultaneousCountdown()
        }
    }

    private func startSimultaneousCountdown() {
        countdownValue = 3
        roundTask?.cancel()
        roundTask = Task { @MainActor in
            for value in stride(from: 2, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                countdownValue = value
            }
            try? await Task.sleep(for: .milliseconds(250))
            countdownValue = nil
            startRoundStimulus()
        }
    }

    private func startTurnBasedTurn() {
        showPassDevice = false
        triggerFired = false
        earlyPlayers = []
        roundAnnouncement = nil
        startRoundStimulus()
    }

    private func startRoundStimulus() {
        triggerFired = false
        triggerDate = Date()

        if config.isTurnBased {
            penalties[activePlayerIndex] = 0
        } else {
            penalties = Array(repeating: 0, count: playerCount)
            reactionTimes = Array(repeating: nil, count: playerCount)
        }

        waitTask?.cancel()
        waitTask = Task { @MainActor in
            let delay = Double.random(in: 1.5...5.0)
            try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
            guard !Task.isCancelled else { return }
            triggerFired = true
            triggerDate = Date()
            HapticManager.shared.medium()
        }
    }

    private func handleTap(_ playerIndex: Int) {
        guard !showResult, countdownValue == nil, !showPassDevice else { return }
        guard !config.isTurnBased || playerIndex == activePlayerIndex else { return }

        if !triggerFired {
            penalties[playerIndex] += 500
            earlyPlayers = [playerIndex]
            HapticManager.shared.error()
            return
        }

        guard reactionTimes[playerIndex] == nil else { return }

        let reaction = Int(Date().timeIntervalSince(triggerDate) * 1000) + penalties[playerIndex]
        let clampedReaction = max(1, reaction)
        reactionTimes[playerIndex] = clampedReaction
        matchReactionSums[playerIndex] += clampedReaction
        matchReactionCounts[playerIndex] += 1
        HapticManager.shared.light()

        if config.isTurnBased {
            completeTurnBasedAttempt()
        } else if reactionTimes.allSatisfy({ $0 != nil }) {
            finishRound()
        }
    }

    private func completeTurnBasedAttempt() {
        waitTask?.cancel()

        if activePlayerIndex < playerCount - 1 {
            activePlayerIndex += 1
            roundTask?.cancel()
            roundTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(850))
                guard !Task.isCancelled else { return }
                showPassDevice = true
            }
            return
        }

        finishRound()
    }

    private func finishRound() {
        guard let winner = reactionTimes.enumerated().compactMap({ index, value -> (Int, Int)? in
            guard let value else { return nil }
            return (index, value)
        }).min(by: { $0.1 < $1.1 })?.0 else {
            return
        }

        scores[winner] += 1
        roundAnnouncement = "\(config.activePlayerNames[winner]) takes the round"
        HapticManager.shared.heavy()

        if currentRound >= totalRounds {
            roundTask?.cancel()
            roundTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(900))
                guard !Task.isCancelled else { return }
                withAnimation(Spring.smooth) {
                    showResult = true
                }
            }
            return
        }

        currentRound += 1

        if config.isTurnBased {
            activePlayerIndex = 0
            reactionTimes = Array(repeating: nil, count: playerCount)
            penalties = Array(repeating: 0, count: playerCount)
            earlyPlayers = []
            triggerFired = false

            roundTask?.cancel()
            roundTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1100))
                guard !Task.isCancelled else { return }
                showPassDevice = true
            }
        } else {
            roundTask?.cancel()
            roundTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(950))
                guard !Task.isCancelled else { return }
                roundAnnouncement = nil
                startRoundStimulus()
            }
        }
    }

    private func averageReaction(for playerIndex: Int) -> Int {
        guard matchReactionSums.indices.contains(playerIndex),
              matchReactionCounts.indices.contains(playerIndex),
              matchReactionCounts[playerIndex] > 0 else {
            return Int.max
        }
        return matchReactionSums[playerIndex] / matchReactionCounts[playerIndex]
    }

    private func zoneStatus(playerIndex: Int) -> String {
        if reactionTimes[safe: playerIndex] != nil {
            return "LOCKED"
        }
        return triggerFired ? "TAP NOW" : "WAIT"
    }

    private func zoneState(for playerIndex: Int) -> ReactionZoneState {
        if reactionTimes[safe: playerIndex] != nil {
            return .locked
        }
        return triggerFired ? .armed : .waiting
    }
}

private enum ReactionZoneState {
    case waiting
    case armed
    case locked
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
