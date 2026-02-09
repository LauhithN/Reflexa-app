import SwiftUI

struct GridReactionGameView: View {
    @State private var viewModel: GridReactionViewModel
    @Environment(\.dismiss) private var dismiss

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: GridReactionViewModel(config: config))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            switch viewModel.state {
            case .ready:
                readyView

            case .countdown(let value):
                CountdownOverlay(value: value)

            case .waiting, .active:
                gameView

            case .result:
                resultView

            default:
                EmptyView()
            }
        }
        .onAppear {
            viewModel.startGame()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    private var readyView: some View {
        VStack(spacing: 16) {
            Text("Grid Reaction")
                .font(.gameTitle)
                .foregroundStyle(.white)
            Text("Tap the lit square!")
                .font(.bodyLarge)
                .foregroundStyle(.gray)
        }
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            Text("Round \(viewModel.currentRound)/\(Constants.gridReactionRounds)")
                .font(.playerLabel)
                .foregroundStyle(.gray)

            // 4x4 Grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: viewModel.gridSize),
                spacing: 8
            ) {
                ForEach(0..<(viewModel.gridSize * viewModel.gridSize), id: \.self) { cellIndex in
                    let isActive = viewModel.activeCell == cellIndex

                    Rectangle()
                        .fill(isActive ? Color.success : Color.cardBackground)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            viewModel.cellTapped(cellIndex)
                        }
                        .accessibilityLabel("Cell \(cellIndex + 1). \(isActive ? "Active, tap now" : "Inactive")")
                }
            }
            .padding(.horizontal, 16)

            if !viewModel.roundTimes.isEmpty {
                Text("Last: \(Formatters.reactionTime(viewModel.roundTimes.last!))")
                    .font(.bodyLarge)
                    .monospacedDigit()
                    .foregroundStyle(.gray)
            }
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Text("Grid Reaction")
                .font(.gameTitle)
                .foregroundStyle(.gray)

            Text("Average")
                .font(.bodyLarge)
                .foregroundStyle(.gray)

            Text(Formatters.reactionTime(viewModel.averageTimeMs))
                .font(.resultScore)
                .monospacedDigit()
                .foregroundStyle(.white)

            PercentileBar(percentile: viewModel.percentile)
                .padding(.horizontal, 40)

            // Individual round times
            VStack(spacing: 4) {
                ForEach(Array(viewModel.roundTimes.enumerated()), id: \.offset) { index, time in
                    HStack {
                        Text("Round \(index + 1)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Spacer()
                        Text(Formatters.reactionTime(time))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    }
                }
            }
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
                    gameType: .gridReaction,
                    score: Formatters.reactionTime(viewModel.averageTimeMs),
                    percentile: viewModel.percentile
                )
            }
            .font(.caption)
            .foregroundStyle(.gray)
            .accessibleTapTarget()
        }
    }
}
