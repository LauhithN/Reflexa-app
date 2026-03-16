import SwiftUI

struct GridReactionGameView: View {
    let config: GameConfiguration

    @Environment(\.dismiss) private var dismiss

    @State private var currentRound = 1
    @State private var activeCells: [Int] = []
    @State private var roundWinner: Int?
    @State private var scores: [Int] = []
    @State private var reactionTimes: [Int] = []
    @State private var turnReactionTimes: [Int?] = []
    @State private var showResult = false
    @State private var showPassDevice = false
    @State private var countdownValue: Int? = nil
    @State private var roundAnnouncement: String?
    @State private var activePlayerIndex = 0
    @State private var roundTask: Task<Void, Never>?
    @State private var triggerDate = Date()

    @AppStorage("bestGridReaction") private var bestGridReaction = 9_999

    private var playerCount: Int { config.playerMode.playerCount }
    private var maxRounds: Int { Constants.gridReactionRounds }
    private var compactLayout: Bool { playerCount == 4 }

    var body: some View {
        ZStack {
            AmbientBackground()

            if config.playerMode == .solo {
                soloView
            } else if config.isTurnBased {
                turnBasedView
            } else {
                simultaneousView
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

    private var simultaneousView: some View {
        ZStack {
            MultiplayerArenaLayout(playerCount: playerCount, topInset: 110, bottomInset: 18) { playerIndex in
                simultaneousPanel(for: playerIndex)
            }

            VStack(spacing: 10) {
                PlayerScoreboard(players: livePlayerResults)
                Text("Round \(currentRound) / \(maxRounds)")
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)

                if let roundAnnouncement {
                    roundAnnouncementPill(roundAnnouncement)
                }
            }
            .padding(.top, 14)
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var turnBasedView: some View {
        TurnBasedStageContainer(
            roundTitle: "Round \(currentRound) / \(maxRounds)",
            subtitle: turnBasedSubtitle,
            activePlayerName: config.activePlayerNames[activePlayerIndex],
            activePlayerColor: Color.playerColor(for: activePlayerIndex),
            players: livePlayerResults,
            activePlayerIndex: activePlayerIndex,
            showPassDevice: showPassDevice,
            onReady: startTurnBasedRound
        ) {
            turnBasedPanel(for: activePlayerIndex)
        }
    }

    private func simultaneousPanel(for playerIndex: Int) -> some View {
        let columns = playerCount == 2 ? 3 : 2
        let cellCount = playerCount == 2 ? 6 : 4
        let color = Color.playerColor(for: playerIndex)

        return MultiplayerPlayerPanel(
            name: config.activePlayerNames[playerIndex],
            accentColor: color,
            subtitle: compactLayout ? nil : "Tap the lit cell",
            compact: compactLayout,
            headerTrailing: {
                Text("\(scores[safe: playerIndex] ?? 0)")
                    .font(.monoSmall)
                    .foregroundStyle(color)
                    .monospacedDigit()
            },
            content: {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(config.activePlayerNames[playerIndex]) reaction zone")
    }

    private func turnBasedPanel(for playerIndex: Int) -> some View {
        let color = Color.playerColor(for: playerIndex)

        return VStack(spacing: 18) {
            Text("Tap the lit cell as fast as you can.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(0..<9, id: \.self) { cell in
                    cellView(
                        cell: cell,
                        playerIndex: playerIndex,
                        isActive: activeCells[safe: playerIndex] == cell,
                        size: nil
                    )
                }
            }

            if let reaction = turnReactionTimes[safe: playerIndex] ?? nil {
                Text("\(reaction)ms")
                    .font(.monoLarge)
                    .foregroundStyle(color)
                    .monospacedDigit()
            } else {
                Text("Only the glowing cell scores.")
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cellView(cell: Int, playerIndex: Int, isActive: Bool, size: CGFloat?) -> some View {
        let zoneColor = Color.playerColor(for: playerIndex)

        return RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: isActive
                    ? [zoneColor.opacity(0.95), zoneColor.opacity(0.52)]
                    : [Color.cardBackground, Color.inkPanel],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isActive ? zoneColor.opacity(0.92) : Color.white.opacity(0.08), lineWidth: isActive ? 2 : 1)
            )
            .if(isActive) { view in
                view.shadow(color: zoneColor.opacity(0.45), radius: 10)
            }
            .if(size != nil) { view in
                view.frame(width: size, height: size)
            }
            .if(size == nil) { view in
                view.aspectRatio(1, contentMode: .fit)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(isActive ? 0.18 : 0.05), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        activePlayerIndex = 0
        scores = Array(repeating: 0, count: playerCount)
        reactionTimes = []
        turnReactionTimes = Array(repeating: nil, count: playerCount)
        activeCells = Array(repeating: 0, count: max(1, playerCount))
        roundWinner = nil
        roundAnnouncement = nil
        showResult = false
        showPassDevice = false
        countdownValue = nil
        roundTask?.cancel()

        if config.playerMode == .solo || !config.isTurnBased {
            startCountdown()
        } else {
            showPassDevice = true
        }
    }

    private func startCountdown() {
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

    private func startTurnBasedRound() {
        showPassDevice = false
        roundAnnouncement = nil
        startRound()
    }

    private func startRound() {
        roundWinner = nil

        let cellCount: Int
        switch config.playerMode {
        case .solo:
            cellCount = 9
        case .twoPlayer:
            cellCount = config.isTurnBased ? 9 : 6
        case .fourPlayer:
            cellCount = config.isTurnBased ? 9 : 4
        }

        if config.isTurnBased {
            activeCells[activePlayerIndex] = Int.random(in: 0..<cellCount)
        } else {
            activeCells = (0..<playerCount).map { _ in Int.random(in: 0..<cellCount) }
        }

        triggerDate = Date()
    }

    private func handleTap(playerIndex: Int, cell: Int) {
        guard !showResult, countdownValue == nil, !showPassDevice else { return }

        if config.playerMode == .solo {
            guard activeCells[safe: 0] == cell else {
                HapticManager.shared.error()
                return
            }

            reactionTimes.append(max(1, Int(Date().timeIntervalSince(triggerDate) * 1000)))
            HapticManager.shared.light()
            advanceSoloRound()
            return
        }

        if config.isTurnBased {
            guard playerIndex == activePlayerIndex else { return }
            guard activeCells[safe: playerIndex] == cell else {
                HapticManager.shared.error()
                return
            }

            let reaction = max(1, Int(Date().timeIntervalSince(triggerDate) * 1000))
            turnReactionTimes[playerIndex] = reaction
            HapticManager.shared.light()
            advanceTurnBasedRound()
            return
        }

        guard activeCells[safe: playerIndex] == cell else {
            HapticManager.shared.error()
            return
        }
        guard roundWinner == nil else { return }

        roundWinner = playerIndex
        scores[playerIndex] += 1
        HapticManager.shared.success()
        advanceSimultaneousRound()
    }

    private func advanceSoloRound() {
        if currentRound == maxRounds {
            let average = reactionTimes.isEmpty ? 0 : reactionTimes.reduce(0, +) / reactionTimes.count
            if average > 0 && average < bestGridReaction {
                bestGridReaction = average
            }
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

    private func advanceSimultaneousRound() {
        if let winner = roundWinner {
            roundAnnouncement = "\(config.activePlayerNames[winner]) takes the round"
        }

        if currentRound == maxRounds {
            roundTask?.cancel()
            roundTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(850))
                guard !Task.isCancelled else { return }
                withAnimation(Spring.smooth) {
                    showResult = true
                }
            }
            return
        }

        currentRound += 1
        roundTask?.cancel()
        roundTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            roundAnnouncement = nil
            startRound()
        }
    }

    private func advanceTurnBasedRound() {
        if activePlayerIndex < playerCount - 1 {
            activePlayerIndex += 1
            roundTask?.cancel()
            roundTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(650))
                guard !Task.isCancelled else { return }
                showPassDevice = true
            }
            return
        }

        guard let winner = turnReactionTimes.enumerated().compactMap({ index, value -> (Int, Int)? in
            guard let value else { return nil }
            return (index, value)
        }).min(by: { $0.1 < $1.1 })?.0 else {
            return
        }

        scores[winner] += 1
        roundAnnouncement = "\(config.activePlayerNames[winner]) takes the round"

        if currentRound == maxRounds {
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
        activePlayerIndex = 0
        turnReactionTimes = Array(repeating: nil, count: playerCount)
        roundTask?.cancel()
        roundTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(950))
            guard !Task.isCancelled else { return }
            showPassDevice = true
        }
    }

    private var turnBasedSubtitle: String {
        if let roundAnnouncement, showPassDevice {
            return roundAnnouncement
        }
        return "Each player gets one grid per round."
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
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
