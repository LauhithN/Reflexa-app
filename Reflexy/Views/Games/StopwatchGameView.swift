import SwiftUI

struct StopwatchGameView: View {
    @State private var viewModel: StopwatchViewModel
    @Environment(\.dismiss) private var dismiss

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: StopwatchViewModel(config: config))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch viewModel.config.playerMode {
            case .solo:
                soloView
            case .twoPlayer:
                TwoPlayerSplitView { index in
                    playerPanel(index: index)
                }
            case .fourPlayer:
                FourPlayerGridView { index in
                    playerPanel(index: index)
                }
            }

            // Countdown overlay
            if case .countdown(let value) = viewModel.state {
                CountdownOverlay(value: value)
            }

            // Result overlay
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

    // MARK: - Solo View

    private var soloView: some View {
        playerPanel(index: 0)
            .ignoresSafeArea()
    }

    // MARK: - Player Panel

    private func playerPanel(index: Int) -> some View {
        let stopped = viewModel.playerStopped[index]
        let color = Color.playerColor(for: index)

        return ZStack {
            (stopped ? Color.cardBackground : color.opacity(0.15))

            VStack(spacing: 16) {
                if viewModel.config.playerMode != .solo {
                    Text("P\(index + 1)")
                        .font(.playerLabel)
                        .foregroundStyle(color)
                }

                if stopped, let value = viewModel.stoppedValues[index] {
                    Text(Formatters.stopwatchValue(abs(value)))
                        .font(.resultScore)
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    Text("Score: \(Formatters.stopwatchValue(viewModel.scoreFor(player: index)))")
                        .font(.bodyLarge)
                        .foregroundStyle(.gray)
                } else {
                    Text(Formatters.stopwatchValue(viewModel.currentValue))
                        .font(.countdownNumber)
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    Text("Tap to stop at 0")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                viewModel.playerTapped(index: index)
            }
        )
        .accessibilityLabel("Player \(index + 1). \(stopped ? "Stopped" : "Tap to stop")")
    }

    // MARK: - Result

    private var resultOverlay: some View {
        ZStack {
            Color.appBackground.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Results")
                    .font(.resultTitle)
                    .foregroundStyle(.white)

                ForEach(0..<viewModel.config.playerMode.playerCount, id: \.self) { i in
                    let isWinner = viewModel.winnerIndex == i
                    HStack {
                        if viewModel.config.playerMode != .solo {
                            Text("P\(i + 1)")
                                .font(.playerLabel)
                                .foregroundStyle(Color.playerColor(for: i))
                        }

                        Text(Formatters.stopwatchValue(viewModel.scoreFor(player: i)))
                            .font(.resultScore)
                            .monospacedDigit()
                            .foregroundStyle(isWinner ? Color.success : .white)

                        if isWinner {
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
