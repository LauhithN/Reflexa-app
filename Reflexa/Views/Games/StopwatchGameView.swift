import SwiftUI

struct StopwatchGameView: View {
    let config: GameConfiguration

    @Environment(\.dismiss) private var dismiss

    @State private var phase: TurnPhase = .idle
    @State private var timeValue: Double = 3.0
    @State private var turnStart: Date?
    @State private var ticker: Timer?

    @State private var currentPlayerIndex = 0
    @State private var turnResults: [Double?] = Array(repeating: nil, count: 4)
    @State private var showPassDevice = false
    @State private var showResult = false
    @State private var ghostItems: [String] = []

    @AppStorage("bestTime") private var bestTime = 9999.0

    var body: some View {
        ZStack {
            AmbientBackground()

            if config.playerMode == .solo {
                soloTurnView
            } else {
                multiplayerTurnView
            }

            if showPassDevice {
                PassDeviceScreen(
                    playerName: activePlayerName,
                    playerColor: activePlayerColor,
                    onReady: {
                        withAnimation(Spring.smooth) {
                            showPassDevice = false
                        }
                        resetTurn()
                    }
                )
            }

            if showResult {
                ResultScreen(
                    scores: resultPayload,
                    scoreLabel: "distance from zero",
                    gameType: .stopwatch,
                    onPlayAgain: restartGame,
                    onHome: { dismiss() }
                )
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !showPassDevice && !showResult else { return }
            handleTap()
        }
        .onAppear {
            restartGame()
        }
        .onDisappear {
            ticker?.invalidate()
            ticker = nil
        }
        .gameScaffold(title: "Stopwatch", gameType: .stopwatch) {
            ticker?.invalidate()
            dismiss()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    private var soloTurnView: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 40)

            Text("Stop at 0.000")
                .font(.sectionTitle)
                .foregroundStyle(Color.textSecondary)

            Text(String(format: "%.3f", timeValue))
                .font(.monoLarge)
                .monospacedDigit()
                .foregroundStyle(displayColor)

            if phase == .idle {
                PulsingText(text: "Tap to Start", color: .accentPrimary)
            } else {
                Text("Tap to Stop")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
            }

            if !ghostItems.isEmpty {
                GhostList(items: ghostItems)
                    .padding(.top, 12)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var multiplayerTurnView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)

            Text("\(activePlayerName)'s Turn")
                .font(.resultTitle)
                .foregroundStyle(activePlayerColor)
                .lineLimit(1)

            Text(String(format: "%.3f", timeValue))
                .font(.monoLarge)
                .monospacedDigit()
                .foregroundStyle(displayColor)

            Text(phase == .idle ? "Tap to Start" : "Tap to Stop")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            if turnResults.contains(where: { $0 != nil }) {
                VStack(spacing: 6) {
                    ForEach(0..<playerCount, id: \.self) { index in
                        if let score = turnResults[index] {
                            HStack {
                                Circle()
                                    .fill(Color.playerColor(for: index))
                                    .frame(width: 8, height: 8)
                                Text(config.activePlayerNames[index])
                                    .font(.monoSmall)
                                    .foregroundStyle(Color.textSecondary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int(score.rounded()))ms")
                                    .font(.monoSmall)
                                    .foregroundStyle(Color.textPrimary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .padding(12)
                .glassCard(cornerRadius: 14)
                .padding(.horizontal, 22)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .playerBorder(color: activePlayerColor, width: 2)
        .padding(12)
    }

    private var displayColor: Color {
        if abs(timeValue) < 0.1 { return .accentSecondary }
        if abs(timeValue) < 0.3 { return .accentAmber }
        return .textPrimary
    }

    private var playerCount: Int {
        config.playerMode.playerCount
    }

    private var activePlayerName: String {
        config.activePlayerNames[currentPlayerIndex]
    }

    private var activePlayerColor: Color {
        Color.playerColor(for: currentPlayerIndex)
    }

    private var resultPayload: [PlayerResult] {
        if config.playerMode == .solo {
            let soloScore = abs(timeValue) * 1000
            let isNewBest = soloScore <= bestTime
            return [
                PlayerResult(
                    name: config.activePlayerNames[0],
                    color: .player1Color,
                    score: soloScore,
                    isWinner: true,
                    isNewBest: isNewBest,
                    rank: 1
                )
            ]
        }

        let ranked = (0..<playerCount)
            .map { index in
                (index, turnResults[index] ?? 9_999)
            }
            .sorted { $0.1 < $1.1 }

        return ranked.enumerated().map { rankOffset, item in
            let index = item.0
            let rank = rankOffset + 1
            return PlayerResult(
                name: config.activePlayerNames[index],
                color: Color.playerColor(for: index),
                score: item.1,
                isWinner: rank == 1,
                isNewBest: false,
                rank: rank
            )
        }
    }

    private func restartGame() {
        ticker?.invalidate()
        ticker = nil
        phase = .idle
        timeValue = 3.0
        turnStart = nil
        currentPlayerIndex = 0
        turnResults = Array(repeating: nil, count: 4)
        showResult = false

        if config.playerMode == .solo {
            showPassDevice = false
        } else {
            showPassDevice = true
        }
    }

    private func resetTurn() {
        ticker?.invalidate()
        ticker = nil
        phase = .idle
        timeValue = 3.0
        turnStart = nil
    }

    private func startTurn() {
        HapticManager.shared.medium()
        phase = .running
        turnStart = Date()

        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            guard let turnStart else { return }
            let elapsed = Date().timeIntervalSince(turnStart)
            timeValue = 3.0 - elapsed
        }
    }

    private func stopTurn() {
        ticker?.invalidate()
        ticker = nil
        phase = .stopped
        HapticManager.shared.heavy()

        let scoreMs = abs(timeValue) * 1000

        if config.playerMode == .solo {
            let isNewBest = scoreMs < bestTime
            if isNewBest {
                bestTime = scoreMs
                HapticManager.shared.doublePulse()
            }

            ghostItems.insert(String(format: "%.3f", timeValue), at: 0)
            ghostItems = Array(ghostItems.prefix(5))

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(Spring.smooth) {
                    showResult = true
                }
            }
            return
        }

        turnResults[currentPlayerIndex] = scoreMs

        if currentPlayerIndex >= playerCount - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(Spring.smooth) {
                    showResult = true
                }
            }
        } else {
            currentPlayerIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(Spring.smooth) {
                    showPassDevice = true
                }
            }
        }
    }

    private func handleTap() {
        switch phase {
        case .idle:
            startTurn()
        case .running:
            stopTurn()
        case .stopped:
            break
        }
    }
}

private enum TurnPhase {
    case idle
    case running
    case stopped
}
