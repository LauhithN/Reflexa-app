import SwiftUI

struct VibrationReflexGameView: View {
    @State private var viewModel: VibrationReflexViewModel
    @Environment(\.dismiss) private var dismiss

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: VibrationReflexViewModel(config: config))
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            switch viewModel.config.playerMode {
            case .solo:
                soloContent
            case .twoPlayer:
                TwoPlayerSplitView { index in
                    playerPanel(index: index)
                }
            case .fourPlayer:
                FourPlayerGridView { index in
                    playerPanel(index: index)
                }
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
        case .waiting, .active: return .black // No visual cue at all
        case .falseStart: return Color.warning.opacity(0.3)
        default: return .appBackground
        }
    }

    private var soloContent: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .waiting:
                Text("Feel...")
                    .font(.bodyLarge)
                    .foregroundStyle(.gray.opacity(0.5))

            case .active:
                // No visual cue — just tap when you feel the vibration
                EmptyView()

            case .falseStart:
                VStack(spacing: 16) {
                    Text("FALSE START!")
                        .font(.resultTitle)
                        .foregroundStyle(Color.error)
                    Button("Try Again") {
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
                }

            default:
                EmptyView()
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                viewModel.playerTapped(index: 0)
            }
        )
    }

    private func playerPanel(index: Int) -> some View {
        let color = Color.playerColor(for: index)

        return ZStack {
            color.opacity(0.05)

            VStack(spacing: 8) {
                Text("P\(index + 1)")
                    .font(.playerLabel)
                    .foregroundStyle(color)

                if let time = viewModel.reactionTimes[index] {
                    Text(Formatters.reactionTime(time))
                        .font(.resultScore)
                        .monospacedDigit()
                        .foregroundStyle(.white)
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
                Text("Vibration Reflex")
                    .font(.gameTitle)
                    .foregroundStyle(.gray)

                if viewModel.config.playerMode == .solo {
                    if let ms = viewModel.reactionTimes[0] {
                        Text(Formatters.reactionTime(ms))
                            .font(.resultScore)
                            .monospacedDigit()
                            .foregroundStyle(.white)

                        PercentileBar(percentile: viewModel.percentile)
                            .padding(.horizontal, 40)
                    }
                } else {
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
                                    .foregroundStyle(.white)
                            }
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
