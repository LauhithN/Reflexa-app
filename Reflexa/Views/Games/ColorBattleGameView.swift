import SwiftUI

struct ColorBattleGameView: View {
    let config: GameConfiguration

    @Environment(\.dismiss) private var dismiss

    @State private var currentRound = 1
    @State private var currentPlayerIndex = 0
    @State private var scores: [Int] = []

    @State private var showPassDevice = false
    @State private var showResult = false
    @State private var roundAnnouncement: String?

    @State private var targetIndices: [Int] = []
    @State private var currentIndices: [Int] = []
    @State private var cycleTimer: Timer?
    @State private var lockedPlayers: Set<Int> = []
    @State private var skippedThisRound: Set<Int> = []

    @State private var availablePowerUps: [PowerUp?] = []
    @State private var shieldActive: [Bool] = []
    @State private var doubleActive: [Bool] = []
    @State private var skipNextTurn: [Bool] = []
    @State private var roundMessages: [String?] = []

    private let palette: [(name: String, color: Color)] = [
        ("Red", Color(hex: "#FF3B30")),
        ("Yellow", Color(hex: "#FFD60A")),
        ("Blue", Color(hex: "#0A84FF")),
        ("Green", Color(hex: "#30D158")),
        ("Purple", Color(hex: "#BF5AF2"))
    ]

    private var playerCount: Int { config.playerMode.playerCount }
    private var totalRounds: Int { max(1, config.roundCount / max(playerCount, 1)) }
    private var compactLayout: Bool { playerCount == 4 }

    var body: some View {
        ZStack {
            AmbientBackground()

            if showResult {
                ResultScreen(
                    scores: resultPayload,
                    scoreLabel: "points",
                    gameType: .colorBattle,
                    onPlayAgain: restart,
                    onHome: { dismiss() }
                )
            } else if config.isTurnBased {
                turnBasedView
            } else {
                simultaneousView
            }
        }
        .onAppear {
            restart()
        }
        .onDisappear {
            cycleTimer?.invalidate()
            cycleTimer = nil
        }
        .gameScaffold(title: "Color Battle", gameType: .colorBattle) {
            cycleTimer?.invalidate()
            dismiss()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    private var simultaneousView: some View {
        ZStack {
            MultiplayerArenaLayout(playerCount: playerCount, topInset: 110, bottomInset: 18) { playerIndex in
                simultaneousPanel(for: playerIndex)
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
        }
    }

    private var turnBasedView: some View {
        TurnBasedStageContainer(
            roundTitle: "Round \(currentRound) / \(totalRounds)",
            subtitle: turnBasedSubtitle,
            activePlayerName: activePlayerName,
            activePlayerColor: activePlayerColor,
            players: livePlayerResults,
            activePlayerIndex: currentPlayerIndex,
            showPassDevice: showPassDevice,
            onReady: startTurnBasedRound
        ) {
            turnBasedPanel(for: currentPlayerIndex)
        }
    }

    private func simultaneousPanel(for playerIndex: Int) -> some View {
        let color = Color.playerColor(for: playerIndex)

        return MultiplayerPlayerPanel(
            name: config.activePlayerNames[playerIndex],
            accentColor: color,
            subtitle: compactLayout ? nil : "Match the target color",
            compact: compactLayout,
            inactive: skippedThisRound.contains(playerIndex),
            headerTrailing: {
                Text("\(scores[playerIndex])")
                    .font(.monoSmall)
                    .foregroundStyle(color)
                    .monospacedDigit()
            },
            content: {
                VStack(spacing: compactLayout ? 8 : 12) {
                    targetPill(for: playerIndex, compact: compactLayout)

                    colorArena(playerIndex: playerIndex, compact: compactLayout)

                    activeEffects(for: playerIndex)

                    if let powerUp = availablePowerUps[playerIndex], !lockedPlayers.contains(playerIndex) {
                        Button {
                            activatePowerUp(for: playerIndex)
                        } label: {
                            Text(powerUp.compactTitle)
                        }
                        .buttonStyle(PrimaryCTAButtonStyle(tint: .accentAmber))
                    }

                    Text(roundMessages[playerIndex] ?? defaultMessage(for: playerIndex))
                        .font(.monoSmall)
                        .foregroundStyle(skippedThisRound.contains(playerIndex) ? Color.textTertiary : Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        )
    }

    private func turnBasedPanel(for playerIndex: Int) -> some View {
        VStack(spacing: 16) {
            targetPill(for: playerIndex, compact: false)

            colorArena(playerIndex: playerIndex, compact: false, explicitHeight: 300)

            activeEffects(for: playerIndex)

            if let powerUp = availablePowerUps[playerIndex] {
                Button {
                    activatePowerUp(for: playerIndex)
                } label: {
                    Text(powerUp.buttonTitle)
                }
                .buttonStyle(PrimaryCTAButtonStyle(tint: .accentAmber))
                .padding(.horizontal, 12)
            }

            Text(roundMessages[playerIndex] ?? "Tap the arena to lock your color.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func targetPill(for playerIndex: Int, compact: Bool) -> some View {
        HStack(spacing: 8) {
            Text("Target")
                .font(.monoSmall)
                .foregroundStyle(Color.textSecondary)

            Circle()
                .fill(palette[targetIndices[safe: playerIndex] ?? 0].color)
                .frame(width: compact ? 10 : 12, height: compact ? 10 : 12)

            Text(palette[targetIndices[safe: playerIndex] ?? 0].name)
                .font(compact ? .playerLabel : .sectionTitle)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    private func colorArena(playerIndex: Int, compact: Bool, explicitHeight: CGFloat? = nil) -> some View {
        let arenaHeight = explicitHeight ?? (compact ? 110 : 180)
        let active = !lockedPlayers.contains(playerIndex) && !skippedThisRound.contains(playerIndex)
        let paletteIndex = currentIndices[safe: playerIndex] ?? 0

        return RoundedRectangle(cornerRadius: compact ? 22 : 28, style: .continuous)
            .fill(palette[paletteIndex].color)
            .overlay(
                VStack(spacing: compact ? 6 : 8) {
                    Text(active ? "Tap To Lock" : "Locked")
                        .font(compact ? .playerLabel : .sectionTitle)
                        .foregroundStyle(Color.white)
                        .shadow(radius: 4)

                    Text(palette[paletteIndex].name)
                        .font(.monoSmall)
                        .foregroundStyle(Color.white.opacity(0.9))
                }
            )
            .frame(maxWidth: .infinity)
            .frame(height: arenaHeight)
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 22 : 28, style: .continuous)
                    .stroke(Color.playerColor(for: playerIndex).opacity(0.6), lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: compact ? 22 : 28, style: .continuous))
            .onTapGesture {
                lockColor(for: playerIndex)
            }
    }

    private func activeEffects(for playerIndex: Int) -> some View {
        HStack(spacing: 8) {
            if doubleActive[playerIndex] {
                effectChip(text: "Double", tint: .accentAmber)
            }
            if shieldActive[playerIndex] {
                effectChip(text: "Shield", tint: .accentSecondary)
            }
            if skipNextTurn[playerIndex] {
                effectChip(text: "Skip Next", tint: .accentHot)
            }
        }
    }

    private func effectChip(text: String, tint: Color) -> some View {
        Text(text)
            .font(.monoSmall)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.18))
            .overlay(
                Capsule()
                    .stroke(tint.opacity(0.5), lineWidth: 1)
            )
            .clipShape(Capsule())
    }

    private var resultPayload: [PlayerResult] {
        let ranking = (0..<playerCount).sorted { lhs, rhs in
            scores[lhs] > scores[rhs]
        }

        return ranking.enumerated().map { index, player in
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

    private var livePlayerResults: [PlayerResult] {
        (0..<playerCount).map { index in
            PlayerResult(
                name: config.activePlayerNames[index],
                color: Color.playerColor(for: index),
                score: Double(scores[index]),
                isWinner: false,
                isNewBest: false,
                rank: index + 1
            )
        }
    }

    private var activePlayerName: String {
        config.activePlayerNames[currentPlayerIndex]
    }

    private var activePlayerColor: Color {
        Color.playerColor(for: currentPlayerIndex)
    }

    private func restart() {
        cycleTimer?.invalidate()
        cycleTimer = nil

        currentRound = 1
        currentPlayerIndex = 0
        scores = Array(repeating: 0, count: playerCount)
        targetIndices = Array(repeating: 0, count: playerCount)
        currentIndices = Array(repeating: 0, count: playerCount)
        availablePowerUps = Array(repeating: nil, count: playerCount)
        shieldActive = Array(repeating: false, count: playerCount)
        doubleActive = Array(repeating: false, count: playerCount)
        skipNextTurn = Array(repeating: false, count: playerCount)
        roundMessages = Array(repeating: nil, count: playerCount)
        lockedPlayers = []
        skippedThisRound = []
        roundAnnouncement = nil
        showResult = false
        showPassDevice = false

        if config.isTurnBased {
            showPassDevice = true
        } else {
            beginSimultaneousRound()
        }
    }

    private func beginSimultaneousRound() {
        cycleTimer?.invalidate()
        roundAnnouncement = nil
        lockedPlayers = []
        skippedThisRound = []
        roundMessages = Array(repeating: nil, count: playerCount)
        availablePowerUps = Array(repeating: nil, count: playerCount)

        for index in 0..<playerCount {
            configureRound(for: index)

            if skipNextTurn[index] {
                skipNextTurn[index] = false
                skippedThisRound.insert(index)
                lockedPlayers.insert(index)
                roundMessages[index] = "Skipped this round"
            }
        }

        if lockedPlayers.count == playerCount {
            advanceAfterRound()
            return
        }

        startCycleTimer()
    }

    private func startTurnBasedRound() {
        showPassDevice = false
        roundAnnouncement = nil
        roundMessages[currentPlayerIndex] = nil
        lockedPlayers.removeAll()
        skippedThisRound.removeAll()
        cycleTimer?.invalidate()

        if skipNextTurn[currentPlayerIndex] {
            skipNextTurn[currentPlayerIndex] = false
            roundMessages[currentPlayerIndex] = "Skipped this round"
            roundAnnouncement = "\(activePlayerName) was skipped"

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                advanceTurnBasedFlow()
            }
            return
        }

        configureRound(for: currentPlayerIndex)
        startCycleTimer()
    }

    private func configureRound(for playerIndex: Int) {
        targetIndices[playerIndex] = Int.random(in: 0..<palette.count)
        currentIndices[playerIndex] = Int.random(in: 0..<palette.count)
        availablePowerUps[playerIndex] = Double.random(in: 0...1) < 0.3 ? PowerUp.allCases.randomElement() : nil
        roundMessages[playerIndex] = nil
    }

    private func startCycleTimer() {
        cycleTimer?.invalidate()
        cycleTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
            if config.isTurnBased {
                guard !lockedPlayers.contains(currentPlayerIndex) else { return }
                currentIndices[currentPlayerIndex] = Int.random(in: 0..<palette.count)
            } else {
                for index in 0..<playerCount where !lockedPlayers.contains(index) && !skippedThisRound.contains(index) {
                    currentIndices[index] = Int.random(in: 0..<palette.count)
                }
            }
        }
    }

    private func activatePowerUp(for playerIndex: Int) {
        guard let powerUp = availablePowerUps[playerIndex] else { return }
        availablePowerUps[playerIndex] = nil

        switch powerUp {
        case .double:
            doubleActive[playerIndex] = true
            roundMessages[playerIndex] = "Double armed"
        case .shield:
            shieldActive[playerIndex] = true
            roundMessages[playerIndex] = "Shield armed"
        case .skip:
            let next = (playerIndex + 1) % playerCount
            skipNextTurn[next] = true
            roundMessages[playerIndex] = "\(config.activePlayerNames[next]) skips next"
        }

        HapticManager.shared.medium()
        HapticManager.shared.warning()
    }

    private func lockColor(for playerIndex: Int) {
        guard !showResult, !showPassDevice else { return }
        guard !skippedThisRound.contains(playerIndex), !lockedPlayers.contains(playerIndex) else { return }
        guard !config.isTurnBased || playerIndex == currentPlayerIndex else { return }

        let matched = currentIndices[playerIndex] == targetIndices[playerIndex]
        var points = matched ? 1 : -1

        if doubleActive[playerIndex] {
            points *= 2
            doubleActive[playerIndex] = false
        }

        if points < 0, shieldActive[playerIndex] {
            points = 0
            shieldActive[playerIndex] = false
        }

        scores[playerIndex] += points
        lockedPlayers.insert(playerIndex)
        cycleTimer?.invalidate()

        if matched {
            roundMessages[playerIndex] = "+\(points)"
            HapticManager.shared.success()
        } else if points == 0 {
            roundMessages[playerIndex] = "Shielded"
            HapticManager.shared.warning()
        } else {
            roundMessages[playerIndex] = "\(points)"
            HapticManager.shared.error()
        }

        if config.isTurnBased {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                advanceTurnBasedFlow()
            }
            return
        }

        if lockedPlayers.count == playerCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                advanceAfterRound()
            }
        } else {
            startCycleTimer()
        }
    }

    private func advanceTurnBasedFlow() {
        if currentPlayerIndex < playerCount - 1 {
            currentPlayerIndex += 1
            withAnimation(Spring.smooth) {
                showPassDevice = true
            }
            return
        }

        advanceAfterRound()
    }

    private func advanceAfterRound() {
        cycleTimer?.invalidate()
        cycleTimer = nil
        roundAnnouncement = leaderLine

        if currentRound >= totalRounds {
            withAnimation(Spring.smooth) {
                showResult = true
            }
            return
        }

        currentRound += 1
        currentPlayerIndex = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if config.isTurnBased {
                withAnimation(Spring.smooth) {
                    showPassDevice = true
                }
            } else {
                beginSimultaneousRound()
            }
        }
    }

    private var leaderLine: String {
        let maxScore = scores.max() ?? 0
        let leaders = scores.enumerated()
            .filter { $0.element == maxScore }
            .map { config.activePlayerNames[$0.offset] }

        if leaders.count == 1 {
            return "Leader: \(leaders[0])"
        }
        return "Tie: \(leaders.joined(separator: ", "))"
    }

    private func defaultMessage(for playerIndex: Int) -> String {
        if skippedThisRound.contains(playerIndex) {
            return "Skipped this round"
        }
        if lockedPlayers.contains(playerIndex) {
            return "Locked in"
        }
        return "Tap the arena to lock your color."
    }

    private var turnBasedSubtitle: String {
        if let roundAnnouncement, showPassDevice {
            return roundAnnouncement
        }
        return "Each player locks one color per round."
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

private enum PowerUp: CaseIterable {
    case double
    case shield
    case skip

    var buttonTitle: String {
        switch self {
        case .double:
            return "Use Double Points"
        case .shield:
            return "Use Shield"
        case .skip:
            return "Use Skip"
        }
    }

    var compactTitle: String {
        switch self {
        case .double:
            return "Double"
        case .shield:
            return "Shield"
        case .skip:
            return "Skip"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
