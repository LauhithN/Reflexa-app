import SwiftUI

struct ColorFlashGameView: View {
    @State private var viewModel: ColorFlashViewModel
    @Environment(\.dismiss) private var dismiss

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: ColorFlashViewModel(config: config))
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            switch viewModel.state {
            case .ready:
                readyView

            case .countdown(let value):
                CountdownOverlay(value: value)

            case .waiting:
                PulsingText(text: "Wait...", color: .waiting)

            case .active:
                VStack {
                    Text("TAP NOW!")
                        .font(.resultTitle)
                        .foregroundStyle(.white)
                }

            case .falseStart:
                VStack(spacing: 16) {
                    Text("FALSE START!")
                        .font(.resultTitle)
                        .foregroundStyle(Color.error)

                    Button("Try Again") {
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

    private var backgroundColor: Color {
        switch viewModel.state {
        case .active: return .red
        case .falseStart: return Color.warning.opacity(0.3)
        default: return .appBackground
        }
    }

    private var readyView: some View {
        VStack(spacing: 16) {
            Text("Color Flash")
                .font(.gameTitle)
                .foregroundStyle(.white)
            Text("Tap when the screen turns RED")
                .font(.bodyLarge)
                .foregroundStyle(.gray)
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Text("Your Time")
                .font(.gameTitle)
                .foregroundStyle(.gray)

            Text(Formatters.reactionTime(viewModel.reactionTimeMs))
                .font(.resultScore)
                .monospacedDigit()
                .foregroundStyle(.white)

            PercentileBar(percentile: viewModel.percentile)
                .padding(.horizontal, 40)

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
                    gameType: .colorFlash,
                    score: Formatters.reactionTime(viewModel.reactionTimeMs),
                    percentile: viewModel.percentile
                )
            }
            .font(.caption)
            .foregroundStyle(.gray)
            .accessibleTapTarget()
        }
    }
}
