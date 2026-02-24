import SwiftUI

struct ColorBattleGameView: View {
    let config: GameConfiguration

    @Environment(\.dismiss) private var dismiss

    @State private var currentRound = 1
    @State private var currentPlayerIndex = 0
    @State private var scores: [Int] = []

    @State private var showPassDevice = true
    @State private var showResult = false

    @State private var targetIndex = 0
    @State private var currentIndex = 0
    @State private var cycleTimer: Timer?
    @State private var turnActive = false

    @State private var availablePowerUp: PowerUp?
    @State private var shieldActive: [Bool] = []
    @State private var doubleActive: [Bool] = []
    @State private var skipNextTurn: [Bool] = []

    @State private var statusMessage: String?

    private let palette: [(name: String, color: Color)] = [
        ("Red", Color(hex: "#FF3B30")),
        ("Yellow", Color(hex: "#FFD60A")),
        ("Blue", Color(hex: "#0A84FF")),
        ("Green", Color(hex: "#30D158")),
        ("Purple", Color(hex: "#BF5AF2"))
    ]

    private var playerCount: Int { config.playerMode.playerCount }
    private var totalRounds: Int { config.roundCount }

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
            } else if showPassDevice {
                PassDeviceScreen(
                    playerName: activePlayerName,
                    playerColor: activePlayerColor,
                    onReady: {
                        withAnimation(Spring.smooth) {
                            showPassDevice = false
                        }
                        beginTurn()
                    }
                )
            } else {
                activeTurnView
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

    private var activeTurnView: some View {
        VStack(spacing: 16) {
            header

            targetPill

            colorArena

            if let availablePowerUp {
                Button {
                    activatePowerUp(availablePowerUp)
                } label: {
                    Text(availablePowerUp.label)
                        .font(.playerLabel)
                }
                .buttonStyle(PrimaryCTAButtonStyle(tint: .accentAmber))
                .padding(.horizontal, 22)
            }

            Spacer(minLength: 0)

            PlayerScoreboard(players: livePlayerResults)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .padding(.top, 16)
        .overlay(alignment: .bottom) {
            if let statusMessage {
                Text(statusMessage)
                    .font(.monoSmall)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                    .padding(.bottom, 84)
                    .transition(.opacity)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Round \(currentRound) / \(totalRounds)")
                .font(.monoSmall)
                .foregroundStyle(Color.textSecondary)

            Text("\(activePlayerName)'s Turn")
                .font(.resultTitle)
                .foregroundStyle(activePlayerColor)
                .lineLimit(1)
        }
    }

    private var targetPill: some View {
        HStack(spacing: 8) {
            Text("Target")
                .font(.monoSmall)
                .foregroundStyle(Color.textSecondary)

            Circle()
                .fill(palette[targetIndex].color)
                .frame(width: 12, height: 12)

            Text(palette[targetIndex].name)
                .font(.playerLabel)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    private var colorArena: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(palette[currentIndex].color)
            .overlay(
                VStack(spacing: 8) {
                    Text(turnActive ? "Tap To Lock" : "Locked")
                        .font(.sectionTitle)
                        .foregroundStyle(Color.white)
                        .shadow(radius: 4)

                    Text(palette[currentIndex].name)
                        .font(.monoSmall)
                        .foregroundStyle(Color.white.opacity(0.9))
                }
            )
            .frame(maxWidth: .infinity)
            .frame(height: 320)
            .padding(.horizontal, 16)
            .onTapGesture {
                lockColor()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(activePlayerColor.opacity(0.6), lineWidth: 2)
            )
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
        shieldActive = Array(repeating: false, count: playerCount)
        doubleActive = Array(repeating: false, count: playerCount)
        skipNextTurn = Array(repeating: false, count: playerCount)

        availablePowerUp = nil
        statusMessage = nil
        showResult = false
        showPassDevice = true
        turnActive = false
    }

    private func beginTurn() {
        guard !showResult else { return }

        if skipNextTurn[currentPlayerIndex] {
            skipNextTurn[currentPlayerIndex] = false
            statusMessage = "\(activePlayerName)'s turn skipped"
            HapticManager.shared.warning()
            advanceToNextTurn()
            return
        }

        targetIndex = Int.random(in: 0..<palette.count)
        currentIndex = Int.random(in: 0..<palette.count)
        turnActive = true
        statusMessage = nil

        availablePowerUp = Double.random(in: 0...1) < 0.3 ? PowerUp.allCases.randomElement() : nil

        cycleTimer?.invalidate()
        cycleTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
            guard turnActive else { return }
            currentIndex = Int.random(in: 0..<palette.count)
        }
    }

    private func activatePowerUp(_ powerUp: PowerUp) {
        availablePowerUp = nil

        switch powerUp {
        case .double:
            doubleActive[currentPlayerIndex] = true
        case .shield:
            shieldActive[currentPlayerIndex] = true
        case .skip:
            let next = (currentPlayerIndex + 1) % playerCount
            skipNextTurn[next] = true
        }

        HapticManager.shared.medium()
        HapticManager.shared.warning()
    }

    private func lockColor() {
        guard turnActive else { return }

        turnActive = false
        cycleTimer?.invalidate()
        cycleTimer = nil

        let matched = currentIndex == targetIndex
        var points = matched ? 1 : -1

        if doubleActive[currentPlayerIndex] {
            points *= 2
            doubleActive[currentPlayerIndex] = false
        }

        if points < 0, shieldActive[currentPlayerIndex] {
            points = 0
            shieldActive[currentPlayerIndex] = false
        }

        scores[currentPlayerIndex] += points

        if matched {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.error()
        }

        statusMessage = scoreLine

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            advanceToNextTurn()
        }
    }

    private var scoreLine: String {
        config.activePlayerNames.enumerated().map { index, name in
            "\(name): \(scores[index])"
        }.joined(separator: "  |  ")
    }

    private func advanceToNextTurn() {
        if currentRound >= totalRounds {
            withAnimation(Spring.smooth) {
                showResult = true
            }
            return
        }

        currentRound += 1
        currentPlayerIndex = (currentPlayerIndex + 1) % playerCount
        withAnimation(Spring.smooth) {
            showPassDevice = true
        }
    }
}

private enum PowerUp: CaseIterable {
    case double
    case shield
    case skip

    var label: String {
        switch self {
        case .double: return "⚡ Double Points"
        case .shield: return "🛡 Shield"
        case .skip: return "⏩ Skip Opponent"
        }
    }
}
