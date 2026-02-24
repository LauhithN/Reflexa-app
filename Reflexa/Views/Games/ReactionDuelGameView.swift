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

    @State private var triggerFired = false
    @State private var triggerDate = Date()
    @State private var showResult = false
    @State private var countdownValue: Int? = 3

    @State private var roundTask: Task<Void, Never>?
    @State private var waitTask: Task<Void, Never>?

    private var playerCount: Int { config.playerMode.playerCount }
    private var totalRounds: Int { Constants.reactionDuelRounds }

    var body: some View {
        ZStack {
            AmbientBackground()

            if config.playerMode == .solo {
                unsupportedView
            } else {
                duelPlayfield
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

    private var duelPlayfield: some View {
        ZStack {
            if config.playerMode == .twoPlayer {
                TwoPlayerSplitView { playerIndex in
                    playerZone(playerIndex)
                }
            } else {
                FourPlayerGridView { playerIndex in
                    playerZone(playerIndex)
                }
            }

            VStack(spacing: 10) {
                PlayerScoreboard(players: livePlayerResults)

                Text("Round \(currentRound) / \(totalRounds)")
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.top, 14)

            centerTrigger
        }
    }

    private var centerTrigger: some View {
        VStack(spacing: 8) {
            PulseOrb(
                color: triggerFired ? .accentAmber : .accentPrimary,
                size: 120,
                pulseScale: 1.2,
                pulseDuration: 1.2
            )

            Text(triggerFired ? "TAP!" : "WAIT...")
                .font(.resultTitle)
                .foregroundStyle(triggerFired ? Color.accentAmber : Color.textSecondary)
        }
    }

    private func playerZone(_ playerIndex: Int) -> some View {
        let name = config.activePlayerNames[playerIndex]
        let color = Color.playerColor(for: playerIndex)

        return VStack(spacing: 12) {
            HStack {
                Text(name)
                    .font(.playerLabel)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text("W \(scores[safe: playerIndex] ?? 0)")
                    .font(.monoSmall)
                    .foregroundStyle(color)
            }

            Text(zoneStatus(playerIndex: playerIndex))
                .font(.sectionTitle)
                .foregroundStyle(triggerFired ? Color.accentAmber : Color.textSecondary)

            if let reaction = reactionTimes[safe: playerIndex] ?? nil {
                Text("\(reaction)ms")
                    .font(.monoSmall)
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
            }

            if earlyPlayers.contains(playerIndex), !triggerFired {
                Text("False start +500ms")
                    .font(.monoSmall)
                    .foregroundStyle(Color.destructive)
            }
        }
        .padding(12)
        .background(color.opacity(0.12))
        .playerBorder(color: color, width: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap(playerIndex)
        }
        .accessibilityLabel("\(name) zone")
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
                let lhsReaction = averageReaction(for: lhs)
                let rhsReaction = averageReaction(for: rhs)
                return lhsReaction < rhsReaction
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

    private func averageReaction(for playerIndex: Int) -> Int {
        guard matchReactionSums.indices.contains(playerIndex),
              matchReactionCounts.indices.contains(playerIndex),
              matchReactionCounts[playerIndex] > 0 else {
            return Int.max
        }
        return matchReactionSums[playerIndex] / matchReactionCounts[playerIndex]
    }

    private func restart() {
        guard config.playerMode != .solo else { return }

        currentRound = 1
        scores = Array(repeating: 0, count: playerCount)
        penalties = Array(repeating: 0, count: playerCount)
        reactionTimes = Array(repeating: nil, count: playerCount)
        matchReactionSums = Array(repeating: 0, count: playerCount)
        matchReactionCounts = Array(repeating: 0, count: playerCount)
        earlyPlayers = []
        triggerFired = false
        showResult = false
        countdownValue = 3

        waitTask?.cancel()
        roundTask?.cancel()

        roundTask = Task { @MainActor in
            for value in stride(from: 2, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                countdownValue = value
            }
            try? await Task.sleep(for: .milliseconds(250))
            countdownValue = nil
            startRound()
        }
    }

    private func startRound() {
        triggerFired = false
        triggerDate = Date()
        penalties = Array(repeating: 0, count: playerCount)
        reactionTimes = Array(repeating: nil, count: playerCount)
        earlyPlayers = []

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
        guard !showResult, countdownValue == nil else { return }

        if !triggerFired {
            penalties[playerIndex] += 500
            earlyPlayers.insert(playerIndex)
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

        if reactionTimes.allSatisfy({ $0 != nil }) {
            finishRound()
        }
    }

    private func finishRound() {
        guard let winner = reactionTimes.enumerated().compactMap({ index, value -> (Int, Int)? in
            guard let value else { return nil }
            return (index, value)
        }).min(by: { $0.1 < $1.1 })?.0 else {
            return
        }

        scores[winner] += 1
        HapticManager.shared.heavy()

        if currentRound >= totalRounds {
            withAnimation(Spring.smooth) {
                showResult = true
            }
            return
        }

        currentRound += 1
        roundTask?.cancel()
        roundTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            startRound()
        }
    }

    private func zoneStatus(playerIndex: Int) -> String {
        if !triggerFired {
            return "WAIT"
        }
        if reactionTimes[playerIndex] == nil {
            return "TAP NOW"
        }
        return "LOCKED"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
