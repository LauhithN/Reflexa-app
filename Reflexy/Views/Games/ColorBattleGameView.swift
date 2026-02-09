import SwiftUI

struct ColorBattleGameView: View {
    @State private var viewModel: ColorBattleViewModel
    @Environment(\.dismiss) private var dismiss

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: ColorBattleViewModel(config: config))
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

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

            if case .countdown(let value) = viewModel.state {
                CountdownOverlay(value: value)
            }

            if case .result = viewModel.state {
                resultOverlay
            }
        }
        .onAppear {
            viewModel.startGame()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    private var backgroundColor: Color {
        switch viewModel.state {
        case .active: return .red
        case .falseStart: return Color.warning.opacity(0.3)
        default: return .appBackground
        }
    }

    private func playerPanel(index: Int) -> some View {
        let color = Color.playerColor(for: index)

        return ZStack {
            color.opacity(0.1)

            VStack(spacing: 8) {
                Text("P\(index + 1)")
                    .font(.playerLabel)
                    .foregroundStyle(color)

                Text("\(viewModel.scores[index])")
                    .font(.resultScore)
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text("Round \(viewModel.currentRound)/\(viewModel.config.roundCount)")
                    .font(.caption)
                    .foregroundStyle(.gray)

                if case .stopped = viewModel.state, viewModel.roundWinner == index {
                    Text("Round Won!")
                        .font(.playerLabel)
                        .foregroundStyle(Color.success)
                }

                if case .falseStart(let faulter) = viewModel.state, faulter == index {
                    Text("FALSE START!")
                        .font(.playerLabel)
                        .foregroundStyle(Color.error)
                }
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                viewModel.playerTapped(index: index)
            }
        )
    }

    private var resultOverlay: some View {
        ZStack {
            Color.appBackground.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 24) {
                if let winner = viewModel.matchWinner {
                    Text("Player \(winner + 1) Wins!")
                        .font(.resultTitle)
                        .foregroundStyle(Color.playerColor(for: winner))
                }

                ForEach(0..<viewModel.config.playerMode.playerCount, id: \.self) { i in
                    HStack {
                        Text("P\(i + 1)")
                            .font(.playerLabel)
                            .foregroundStyle(Color.playerColor(for: i))
                        Text("\(viewModel.scores[i]) pts")
                            .font(.bodyLarge)
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    }
                }

                HStack(spacing: 16) {
                    Button("Play Again") {
                        viewModel.resetGame()
                        viewModel.startGame()
                    }
                    .font(.bodyLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.waiting)
                    .clipShape(Capsule())
                    .accessibleTapTarget()

                    Button("Menu") {
                        dismiss()
                    }
                    .font(.bodyLarge)
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.cardBackground)
                    .clipShape(Capsule())
                    .accessibleTapTarget()
                }
            }
        }
    }
}
