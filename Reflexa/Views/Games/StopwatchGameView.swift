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
    @State private var stoppedValues: [Double?] = Array(repeating: nil, count: 4)
    @State private var showPassDevice = false
    @State private var showResult = false
    @State private var ghostItems: [String] = []
    @State private var countdownValue: Int? = nil
    @State private var roundAnnouncement: String?
    @State private var simultaneousStarted = false
    @State private var countdownTask: Task<Void, Never>?

    @AppStorage("bestTime") private var bestTime = 9999.0

    private var playerCount: Int {
        config.playerMode.playerCount
    }

    private var activePlayerName: String {
        config.activePlayerNames[currentPlayerIndex]
    }

    private var activePlayerColor: Color {
        Color.playerColor(for: currentPlayerIndex)
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            if config.playerMode == .solo {
                soloTurnView
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
                    scoreLabel: "distance from zero",
                    gameType: .stopwatch,
                    onPlayAgain: restartGame,
                    onHome: { dismiss() }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            restartGame()
        }
        .onDisappear {
            ticker?.invalidate()
            ticker = nil
            countdownTask?.cancel()
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

            Text(formattedTime(timeValue))
                .font(.monoLarge)
                .monospacedDigit()
                .foregroundStyle(displayColor(for: timeValue))

            Button {
                handleManualTap()
            } label: {
                Text(phase == .idle ? "Tap to Start" : "Tap to Stop")
            }
            .buttonStyle(PrimaryCTAButtonStyle(tint: phase == .running ? .accentAmber : .accentPrimary))
            .padding(.horizontal, 24)

            if !ghostItems.isEmpty {
                GhostList(items: ghostItems)
                    .padding(.top, 12)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var simultaneousView: some View {
        ZStack {
            MultiplayerArenaLayout(playerCount: playerCount, topInset: 110, bottomInset: 18) { playerIndex in
                simultaneousPanel(for: playerIndex)
            }

            VStack(spacing: 10) {
                PlayerScoreboard(players: livePlayerResults)

                Text(simultaneousStarted ? "Tap your lane closest to 0.000" : "Shared countdown starts the whole match")
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
            roundTitle: "Single Round",
            subtitle: turnBasedSubtitle,
            activePlayerName: activePlayerName,
            activePlayerColor: activePlayerColor,
            players: livePlayerResults,
            activePlayerIndex: currentPlayerIndex,
            showPassDevice: showPassDevice,
            onReady: resetTurn
        ) {
            VStack(spacing: 18) {
                Text(formattedTime(timeValue))
                    .font(.monoLarge)
                    .monospacedDigit()
                    .foregroundStyle(displayColor(for: timeValue))

                Text("Start the clock, then stop as close to zero as possible.")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    handleManualTap()
                } label: {
                    Text(phase == .idle ? "Tap to Start" : "Tap to Stop")
                }
                .buttonStyle(PrimaryCTAButtonStyle(tint: phase == .running ? .accentAmber : activePlayerColor))
                .padding(.horizontal, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func simultaneousPanel(for playerIndex: Int) -> some View {
        let color = Color.playerColor(for: playerIndex)
        let lockedScore = turnResults[playerIndex]

        return MultiplayerPlayerPanel(
            name: config.activePlayerNames[playerIndex],
            accentColor: color,
            subtitle: compactSubtitle(for: playerIndex),
            compact: playerCount == 4,
            headerTrailing: {
                if let lockedScore {
                    Text("\(Int(lockedScore.rounded()))ms")
                        .font(.monoSmall)
                        .foregroundStyle(color)
                } else {
                    Text(simultaneousStarted ? "LIVE" : "READY")
                        .font(.monoSmall)
                        .foregroundStyle(Color.textSecondary)
                }
            },
            content: {
                VStack(spacing: playerCount == 4 ? 8 : 12) {
                    Text(formattedTime(displayValue(for: playerIndex)))
                        .font(playerCount == 4 ? .resultTitle : .monoTime)
                        .monospacedDigit()
                        .foregroundStyle(displayColor(for: displayValue(for: playerIndex)))

                    Text(prompt(for: playerIndex))
                        .font(playerCount == 4 ? .monoSmall : .bodyLarge)
                        .foregroundStyle(lockedScore == nil ? Color.textPrimary : Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        )
        .contentShape(RoundedRectangle(cornerRadius: playerCount == 4 ? 22 : 28, style: .continuous))
        .onTapGesture {
            handleSimultaneousTap(playerIndex)
        }
    }

    private func formattedTime(_ value: Double) -> String {
        String(format: "%.3f", value)
    }

    private func displayColor(for value: Double) -> Color {
        if abs(value) < 0.1 { return .accentSecondary }
        if abs(value) < 0.3 { return .accentAmber }
        return .textPrimary
    }

    private func displayValue(for playerIndex: Int) -> Double {
        if let locked = turnResults[playerIndex] {
            return stoppedValues[playerIndex] ?? (locked / 1000)
        }
        return timeValue
    }

    private func compactSubtitle(for playerIndex: Int) -> String? {
        if let locked = turnResults[playerIndex] {
            return "\(Int(locked.rounded()))ms off"
        }
        return simultaneousStarted ? "Tap to stop" : "Stand by"
    }

    private func prompt(for playerIndex: Int) -> String {
        if turnResults[playerIndex] != nil {
            return "Locked in"
        }
        if !simultaneousStarted {
            return "Wait for the shared countdown"
        }
        return "Tap to Stop"
    }

    private var livePlayerResults: [PlayerResult] {
        (0..<playerCount).map { index in
            PlayerResult(
                name: config.activePlayerNames[index],
                color: Color.playerColor(for: index),
                score: turnResults[index] ?? -1,
                isWinner: false,
                isNewBest: false,
                rank: index + 1
            )
        }
    }

    private var resultPayload: [PlayerResult] {
        if config.playerMode == .solo {
            let soloScore = abs(timeValue) * 1000
            let isNewBest = soloScore < bestTime
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
        stoppedValues = Array(repeating: nil, count: 4)
        showPassDevice = false
        showResult = false
        roundAnnouncement = nil
        simultaneousStarted = false
        countdownValue = nil
        countdownTask?.cancel()

        if config.playerMode == .solo {
            return
        }

        if config.isTurnBased {
            showPassDevice = true
        } else {
            startSimultaneousCountdown()
        }
    }

    private func startSimultaneousCountdown() {
        countdownValue = 3

        countdownTask?.cancel()
        countdownTask = Task { @MainActor in
            for value in stride(from: 2, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                countdownValue = value
            }
            try? await Task.sleep(for: .milliseconds(250))
            countdownValue = nil
            startSimultaneousRun()
        }
    }

    private func resetTurn() {
        ticker?.invalidate()
        ticker = nil
        phase = .idle
        timeValue = 3.0
        turnStart = nil
        roundAnnouncement = nil
        showPassDevice = false
    }

    private func startTurn() {
        HapticManager.shared.medium()
        phase = .running
        turnStart = Date()
        startTicker()
    }

    private func startSimultaneousRun() {
        simultaneousStarted = true
        phase = .running
        turnStart = Date()
        startTicker()
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            guard let turnStart else { return }
            let elapsed = Date().timeIntervalSince(turnStart)
            timeValue = 3.0 - elapsed
        }
    }

    private func stopManualTurn() {
        ticker?.invalidate()
        ticker = nil
        phase = .stopped
        HapticManager.shared.heavy()

        let scoreMs = abs(timeValue) * 1000
        stoppedValues[currentPlayerIndex] = timeValue

        if config.playerMode == .solo {
            let isNewBest = scoreMs < bestTime
            if isNewBest {
                bestTime = scoreMs
                HapticManager.shared.doublePulse()
            }

            ghostItems.insert(formattedTime(timeValue), at: 0)
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
            roundAnnouncement = "\(activePlayerName) is up next"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(Spring.smooth) {
                    showPassDevice = true
                }
            }
        }
    }

    private func handleManualTap() {
        switch phase {
        case .idle:
            startTurn()
        case .running:
            stopManualTurn()
        case .stopped:
            break
        }
    }

    private func handleSimultaneousTap(_ playerIndex: Int) {
        guard config.playerMode != .solo, !config.isTurnBased else { return }
        guard simultaneousStarted, phase == .running else { return }
        guard turnResults[playerIndex] == nil else { return }

        let scoreMs = abs(timeValue) * 1000
        turnResults[playerIndex] = scoreMs
        stoppedValues[playerIndex] = timeValue
        HapticManager.shared.light()

        if turnResults.prefix(playerCount).allSatisfy({ $0 != nil }) {
            ticker?.invalidate()
            ticker = nil
            phase = .stopped
            simultaneousStarted = false
            roundAnnouncement = winnerLine

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(Spring.smooth) {
                    showResult = true
                }
            }
        }
    }

    private var winnerLine: String? {
        let finishedResults = turnResults.prefix(playerCount).enumerated().compactMap { index, score -> (Int, Double)? in
            guard let score else { return nil }
            return (index, score)
        }
        guard let winner = finishedResults.min(by: { $0.1 < $1.1 })?.0 else {
            return nil
        }
        return "\(config.activePlayerNames[winner]) is closest to zero"
    }

    private var turnBasedSubtitle: String {
        if let roundAnnouncement, showPassDevice {
            return roundAnnouncement
        }
        return "One player at a time. Closest to zero wins."
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

private enum TurnPhase {
    case idle
    case running
    case stopped
}
