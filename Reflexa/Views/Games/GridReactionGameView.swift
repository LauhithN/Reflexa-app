import SwiftUI

struct GridReactionGameView: View {
    let config: GameConfiguration

    @Environment(\.dismiss) private var dismiss

    @State private var currentRound = 1
    @State private var activeCells: [Int] = []
    @State private var roundWinner: Int?
    @State private var scores: [Int] = []
    @State private var reactionTimes: [Int] = []
    @State private var showResult = false
    @State private var countdownValue: Int? = 3
    @State private var roundTask: Task<Void, Never>?

    @AppStorage("bestGridReaction") private var bestGridReaction = 9_999

    private var playerCount: Int { config.playerMode.playerCount }
    private var maxRounds: Int { Constants.gridReactionRounds }

    @State private var triggerDate = Date()

    var body: some View {
        ZStack {
            AmbientBackground()

            Group {
                switch config.playerMode {
                case .solo:
                    soloView
                case .twoPlayer:
                    multiplayerSplitView
                case .fourPlayer:
                    multiplayerQuadrantView
                }
            }

            if config.playerMode != .solo {
                VStack {
                    PlayerScoreboard(players: livePlayerResults)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    Spacer()
                }
            }

            if let countdownValue {
                CountdownOverlay(value: countdownValue)
            }

            if showResult {
                ResultScreen(
                    scores: resultPayload,
                    scoreLabel: config.playerMode == .solo ? "reaction time" : "round wins",
                    gameType: .gridReaction,
                    onPlayAgain: restartGame,
                    onHome: { dismiss() }
                )
            }
        }
        .onAppear {
            restartGame()
        }
        .onDisappear {
            roundTask?.cancel()
        }
        .gameScaffold(title: "Grid Reaction", gameType: .gridReaction) {
            dismiss()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    private var soloView: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 26)

            Text("Round \(currentRound) / \(maxRounds)")
                .font(.sectionTitle)
                .foregroundStyle(Color.textSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(0..<9, id: \.self) { cell in
                    cellView(
                        cell: cell,
                        playerIndex: 0,
                        isActive: activeCells[safe: 0] == cell,
                        size: 96
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private var multiplayerSplitView: some View {
        TwoPlayerSplitView { playerIndex in
            playerZone(playerIndex: playerIndex, columns: 3, cellCount: 6)
        }
    }

    private var multiplayerQuadrantView: some View {
        FourPlayerGridView { playerIndex in
            playerZone(playerIndex: playerIndex, columns: 2, cellCount: 4)
        }
    }

    private func playerZone(playerIndex: Int, columns: Int, cellCount: Int) -> some View {
        let color = Color.playerColor(for: playerIndex)

        return VStack(spacing: 10) {
            HStack {
                Text(config.activePlayerNames[playerIndex])
                    .font(.playerLabel)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text("\(scores[safe: playerIndex] ?? 0)")
                    .font(.monoSmall)
                    .foregroundStyle(color)
                    .monospacedDigit()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
                ForEach(0..<cellCount, id: \.self) { cell in
                    cellView(
                        cell: cell,
                        playerIndex: playerIndex,
                        isActive: activeCells[safe: playerIndex] == cell,
                        size: nil
                    )
                }
            }
        }
        .padding(12)
        .background(color.opacity(0.12))
        .playerBorder(color: color, width: 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(config.activePlayerNames[playerIndex]) reaction zone")
    }

    private func cellView(cell: Int, playerIndex: Int, isActive: Bool, size: CGFloat?) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isActive ? Color.accentPrimary : Color.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.strokeSubtle, lineWidth: 1)
            )
            .if(isActive) { view in
                view.shadow(color: Color.accentPrimary.opacity(0.45), radius: 8)
            }
            .if(size != nil) { view in
                view.frame(width: size, height: size)
            }
            .if(size == nil) { view in
                view.aspectRatio(1, contentMode: .fit)
            }
            .onTapGesture {
                handleTap(playerIndex: playerIndex, cell: cell)
            }
            .accessibilityLabel(isActive ? "Active cell" : "Inactive cell")
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
        if config.playerMode == .solo {
            let average = reactionTimes.isEmpty ? 0 : reactionTimes.reduce(0, +) / reactionTimes.count
            let isNewBest = average > 0 && average < bestGridReaction
            return [
                PlayerResult(
                    name: config.activePlayerNames[0],
                    color: .player1Color,
                    score: Double(average),
                    isWinner: true,
                    isNewBest: isNewBest,
                    rank: 1
                )
            ]
        }

        let ranked = (0..<playerCount)
            .sorted { scores[$0] > scores[$1] }

        return ranked.enumerated().map { index, player in
            PlayerResult(
                name: config.activePlayerNames[player],
                color: Color.playerColor(for: player),
                score: Double(scores[player]),
                isWinner: index == 0,
                isNewBest: false,
                rank: index + 1
            )
        }
    }

    private func restartGame() {
        currentRound = 1
        scores = Array(repeating: 0, count: playerCount)
        reactionTimes = []
        activeCells = Array(repeating: 0, count: playerCount)
        roundWinner = nil
        showResult = false
        countdownValue = 3
        roundTask?.cancel()

        roundTask = Task { @MainActor in
            for value in stride(from: 2, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                countdownValue = value
            }
            try? await Task.sleep(for: .milliseconds(300))
            countdownValue = nil
            startRound()
        }
    }

    private func startRound() {
        roundWinner = nil

        let cellCount: Int
        switch config.playerMode {
        case .solo: cellCount = 9
        case .twoPlayer: cellCount = 6
        case .fourPlayer: cellCount = 4
        }

        activeCells = (0..<playerCount).map { _ in Int.random(in: 0..<cellCount) }
        triggerDate = Date()
    }

    private func handleTap(playerIndex: Int, cell: Int) {
        guard !showResult, countdownValue == nil else { return }
        guard activeCells[safe: playerIndex] == cell else {
            HapticManager.shared.error()
            return
        }

        let reaction = Int(Date().timeIntervalSince(triggerDate) * 1000)

        if config.playerMode == .solo {
            reactionTimes.append(max(1, reaction))
            HapticManager.shared.light()
            advanceRound()
            return
        }

        guard roundWinner == nil else { return }
        roundWinner = playerIndex
        scores[playerIndex] += 1
        HapticManager.shared.success()
        advanceRound()
    }

    private func advanceRound() {
        if config.playerMode == .solo, currentRound == maxRounds {
            let average = reactionTimes.isEmpty ? 0 : reactionTimes.reduce(0, +) / reactionTimes.count
            if average > 0 && average < bestGridReaction {
                bestGridReaction = average
            }
            withAnimation(Spring.smooth) {
                showResult = true
            }
            return
        }

        if config.playerMode != .solo, currentRound == maxRounds {
            withAnimation(Spring.smooth) {
                showResult = true
            }
            return
        }

        currentRound += 1
        roundTask?.cancel()
        roundTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(650))
            startRound()
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
