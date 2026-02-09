import SwiftUI

struct ReactionDuelGameView: View {
    @State private var viewModel: ReactionDuelViewModel
    @Environment(\.dismiss) private var dismiss

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: ReactionDuelViewModel(config: config))
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

            VStack(spacing: 12) {
                Text("P\(index + 1)")
                    .font(.playerLabel)
                    .foregroundStyle(color)

                if let time = viewModel.reactionTimes[index] {
                    Text(Formatters.reactionTime(time))
                        .font(.resultScore)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                } else if case .active = viewModel.state {
                    Text("TAP!")
                        .font(.gameTitle)
                        .foregroundStyle(.white)
                } else if case .waiting = viewModel.state {
                    Text("Wait...")
                        .font(.bodyLarge)
                        .foregroundStyle(.gray)
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
                if let winner = viewModel.winnerIndex {
                    Text("Player \(winner + 1) Wins!")
                        .font(.resultTitle)
                        .foregroundStyle(Color.playerColor(for: winner))
                }

                ForEach(0..<viewModel.config.playerMode.playerCount, id: \.self) { i in
                    HStack {
                        Text("P\(i + 1)")
                            .font(.playerLabel)
                            .foregroundStyle(Color.playerColor(for: i))

                        if let time = viewModel.reactionTimes[i] {
                            Text(Formatters.reactionTime(time))
                                .font(.bodyLarge)
                                .monospacedDigit()
                                .foregroundStyle(viewModel.winnerIndex == i ? Color.success : .white)
                        } else if viewModel.falseStartPlayer == i {
                            Text("False Start")
                                .font(.bodyLarge)
                                .foregroundStyle(Color.error)
                        }

                        if viewModel.winnerIndex == i {
                            Text("WINNER")
                                .font(.caption)
                                .foregroundStyle(Color.success)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.success.opacity(0.2))
                                .clipShape(Capsule())
                        }
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
