import SwiftUI

struct ColorBattleGameView: View {
    @State private var viewModel: ColorBattleViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var activePresses: Set<Int> = []

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: ColorBattleViewModel(config: config))
    }

    var body: some View {
        ZStack {
            battleBackground.ignoresSafeArea()

            switch viewModel.config.playerMode {
            case .twoPlayer:
                TwoPlayerSplitView { index in
                    playerPanel(index: index)
                }
            case .fourPlayer:
                FourPlayerGridView { index in
                    playerPanel(index: index)
                }
            default:
                EmptyView()
            }

            VStack {
                battleHUD
                Spacer()
            }
            .padding(.top, 8)

            if case .countdown(let value) = viewModel.state {
                CountdownOverlay(value: value)
            }

            if case .stopped = viewModel.state {
                if let winner = viewModel.roundWinner {
                    roundBanner(
                        text: "Round \(viewModel.currentRound): Player \(winner + 1) +\(viewModel.lastRoundPointDelta)",
                        color: Color.playerColor(for: winner)
                    )
                }
            }

            if case .falseStart(let faulter) = viewModel.state, let faulter {
                roundBanner(
                    text: "Player \(faulter + 1) false started: -\(abs(viewModel.lastRoundPointDelta))",
                    color: .error
                )
            }

            if case .result = viewModel.state {
                resultOverlay
            }
        }
        .onAppear {
            viewModel.startGame()
        }
        .onChange(of: viewModel.state) { _, _ in
            activePresses.removeAll()
        }
        .gameScaffold(
            title: "Color Battle",
            gameType: .colorBattle,
            onHowToPlayVisibilityChanged: { isVisible in
                viewModel.setPaused(isVisible)
            }
        ) {
            dismiss()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    @ViewBuilder
    private var battleBackground: some View {
        switch viewModel.state {
        case .active:
            AngularGradient(
                colors: [
                    Color.orange,
                    Color.yellow,
                    Color.red,
                    Color.pink,
                    Color.orange
                ],
                center: .center
            )
        case .falseStart:
            LinearGradient(
                colors: [Color.error.opacity(0.55), Color(red: 0.09, green: 0.04, blue: 0.07)],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.16),
                    Color(red: 0.02, green: 0.03, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var battleHUD: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Color Battle")
                    .font(.gameTitle)
                    .foregroundStyle(.white)
                Spacer()
                Text("Highest after \(viewModel.config.roundCount)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            HStack(spacing: 8) {
                Text("Round \(viewModel.currentRound)/\(viewModel.config.roundCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())

                if viewModel.isPowerRound {
                    Text("POWER +\(viewModel.currentRoundPointValue)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.yellow.opacity(0.18))
                        .clipShape(Capsule())
                }

                Spacer()

                Text(roundStateText)
                    .font(.caption)
                    .foregroundStyle(roundStateColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.waiting, Color.success],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * roundProgress)
                }
            }
            .frame(height: 8)

            scoreStrip
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    private var scoreStrip: some View {
        HStack(spacing: 10) {
            ForEach(0..<viewModel.config.playerMode.playerCount, id: \.self) { index in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.playerColor(for: index))
                        .frame(width: 8, height: 8)
                    Text("P\(index + 1)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text("\(viewModel.scores[index])")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.28))
                .clipShape(Capsule())
            }
        }
    }

    private var roundProgress: CGFloat {
        if case .result = viewModel.state {
            return 1
        }
        guard viewModel.config.roundCount > 0 else { return 0 }
        let completedRounds = max(viewModel.currentRound - 1, 0)
        let raw = Double(completedRounds) / Double(viewModel.config.roundCount)
        return CGFloat(min(max(raw, 0), 1))
    }

    private var roundStateText: String {
        switch viewModel.state {
        case .waiting:
            return viewModel.isPowerRound ? "Power Round Ready" : "Hold"
        case .active:
            return "Signal Live (+\(viewModel.currentRoundPointValue))"
        case .stopped:
            return "Round Locked"
        case .falseStart:
            return "Penalty"
        case .result:
            return "Match Complete"
        default:
            return "Ready"
        }
    }

    private var roundStateColor: Color {
        switch viewModel.state {
        case .active:
            return .success
        case .falseStart:
            return .error
        default:
            return .gray
        }
    }

    private func roundBanner(text: String, color: Color) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(color.opacity(0.78))
                .clipShape(Capsule())
                .padding(.bottom, 20)
        }
    }

    private func playerPanel(index: Int) -> some View {
        let color = Color.playerColor(for: index)

        return ZStack {
            LinearGradient(
                colors: [color.opacity(0.3), color.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                Text("P\(index + 1)")
                    .font(.caption.weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(.gray)

                Text("\(viewModel.scores[index])")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(panelStatusText(for: index))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(panelStatusColor(for: index))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
            }
            .padding(12)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !activePresses.contains(index) else { return }
                    activePresses.insert(index)
                    viewModel.playerTapped(index: index)
                }
                .onEnded { _ in
                    activePresses.remove(index)
                }
        )
    }

    private func panelStatusText(for index: Int) -> String {
        switch viewModel.state {
        case .waiting:
            return "WAIT FOR SIGNAL"
        case .active:
            return "TAP FOR +\(viewModel.currentRoundPointValue)"
        case .stopped:
            return viewModel.roundWinner == index
                ? "+\(max(viewModel.lastRoundPointDelta, 1)) ROUND WIN"
                : "ROUND LOST"
        case .falseStart(let faulter):
            return faulter == index ? "FALSE START (-1)" : "OPPONENT PENALIZED"
        case .result:
            return viewModel.matchWinner == index ? "MATCH WINNER" : "MATCH ENDED"
        default:
            return "READY"
        }
    }

    private func panelStatusColor(for index: Int) -> Color {
        switch viewModel.state {
        case .active:
            return .success
        case .stopped:
            return viewModel.roundWinner == index ? .success : .gray
        case .falseStart(let faulter):
            return faulter == index ? .error : .warning
        case .result:
            return viewModel.matchWinner == index ? .success : .gray
        default:
            return .gray
        }
    }

    private var sortedPlayersByScore: [Int] {
        (0..<viewModel.config.playerMode.playerCount).sorted { lhs, rhs in
            if viewModel.scores[lhs] == viewModel.scores[rhs] {
                return lhs < rhs
            }
            return viewModel.scores[lhs] > viewModel.scores[rhs]
        }
    }

    private func finalScoreRow(player index: Int, maxScore: Int) -> some View {
        HStack(spacing: 10) {
            Text("P\(index + 1)")
                .font(.playerLabel)
                .foregroundStyle(Color.playerColor(for: index))
                .frame(width: 50, alignment: .leading)

            GeometryReader { geo in
                let progress = CGFloat(viewModel.scores[index]) / CGFloat(max(maxScore, 1))
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))

                    Capsule()
                        .fill(Color.playerColor(for: index))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 10)

            Text("\(viewModel.scores[index])")
                .font(.bodyLarge)
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(width: 34, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.cardBackground.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.84).ignoresSafeArea()

            VStack(spacing: 20) {
                if let winner = viewModel.matchWinner {
                    Text("Player \(winner + 1) Wins The Match")
                        .font(.resultTitle)
                        .foregroundStyle(Color.playerColor(for: winner))
                }

                if viewModel.tieBreakUsed {
                    Text("Tie broken by final winning round")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Text("Final Scoreboard")
                    .font(.caption)
                    .foregroundStyle(.gray)

                let maxScore = viewModel.scores.max() ?? 1

                VStack(spacing: 10) {
                    ForEach(sortedPlayersByScore, id: \.self) { player in
                        finalScoreRow(player: player, maxScore: maxScore)
                    }
                }
                .padding(.horizontal, 22)

                GameActionButtons(primaryTint: .accentPrimary) {
                    viewModel.resetGame()
                    viewModel.startGame()
                } onSecondary: {
                    dismiss()
                }
                .padding(.horizontal, 22)
            }
            .padding(.top, 24)
        }
    }
}
