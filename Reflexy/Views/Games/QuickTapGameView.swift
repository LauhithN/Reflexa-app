import SwiftUI

struct QuickTapGameView: View {
    @State private var viewModel: QuickTapViewModel
    @Environment(\.dismiss) private var dismiss

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: QuickTapViewModel(config: config))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch viewModel.state {
            case .ready:
                readyView

            case .countdown(let value):
                CountdownOverlay(value: value)

            case .active:
                activeView

            case .result:
                resultView

            default:
                EmptyView()
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                viewModel.playerTapped(index: 0)
            }
        )
        .onAppear {
            viewModel.startGame()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    private var readyView: some View {
        VStack(spacing: 16) {
            Text("Quick Tap")
                .font(.gameTitle)
                .foregroundStyle(.white)
            Text("Tap as fast as you can!")
                .font(.bodyLarge)
                .foregroundStyle(.gray)
        }
    }

    private var activeView: some View {
        VStack(spacing: 24) {
            Text(String(format: "%.1f", viewModel.timeRemaining))
                .font(.countdownNumber)
                .monospacedDigit()
                .foregroundStyle(viewModel.timeRemaining <= 3 ? Color.error : .white)

            Text("\(viewModel.tapCount)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.success)

            Text("TAP!")
                .font(.gameTitle)
                .foregroundStyle(.gray)
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Text("Time's Up!")
                .font(.gameTitle)
                .foregroundStyle(.gray)

            Text("\(viewModel.tapCount)")
                .font(.resultScore)
                .monospacedDigit()
                .foregroundStyle(.white)

            Text("taps in 10 seconds")
                .font(.bodyLarge)
                .foregroundStyle(.gray)

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

            Button("Share") {
                ShareService.shareResult(
                    gameType: .quickTap,
                    score: Formatters.tapCount(viewModel.tapCount),
                    percentile: nil
                )
            }
            .font(.caption)
            .foregroundStyle(.gray)
            .accessibleTapTarget()
        }
    }
}
