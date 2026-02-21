import SwiftUI

struct SequenceMemoryGameView: View {
    @State private var viewModel: SequenceMemoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var displayedScore: Int = 0

    private let accentColor = Color.accentPrimary

    private let cellColors: [Color] = [
        Color(hex: "5B8CFF"), // blue
        Color(hex: "F87171"), // red
        Color(hex: "34D399"), // green
        Color(hex: "F59E0B"), // amber
    ]

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: SequenceMemoryViewModel(config: config))
    }

    var body: some View {
        ZStack {
            backgroundView.ignoresSafeArea()

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
        .onAppear {
            viewModel.startGame()
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .result = newState {
                animateScoreCountUp()
            }
        }
        .gameScaffold(
            title: "Sequence Memory",
            gameType: .sequenceMemory,
            onHowToPlayVisibilityChanged: { isVisible in
                viewModel.setPaused(isVisible)
            }
        ) {
            dismiss()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        if case .result = viewModel.state {
            LinearGradient(
                colors: [
                    accentColor.opacity(0.18),
                    Color(red: 0.04, green: 0.02, blue: 0.08),
                    Color(red: 0.02, green: 0.01, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            AmbientBackground()
        }
    }

    // MARK: - Ready

    private var readyView: some View {
        VStack(spacing: 18) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(accentColor)

            Text("Sequence Memory")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)

            Text("Watch, remember, repeat!")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Text("Each level adds one more step")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(22)
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, 18)
    }

    // MARK: - Active

    private var activeView: some View {
        VStack(spacing: 28) {
            // Level counter
            Text("Level \(viewModel.level)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            // Status text
            Text(viewModel.isShowingSequence ? "Watch..." : "Your turn")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(viewModel.isShowingSequence ? accentColor : Color.success)

            // 2x2 Grid
            let columns = [
                GridItem(.fixed(140), spacing: 16),
                GridItem(.fixed(140), spacing: 16)
            ]

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    cellView(index: index)
                }
            }
            .padding(.horizontal, 24)

            // Progress dots
            if !viewModel.isShowingSequence && viewModel.sequence.count > 0 {
                HStack(spacing: 6) {
                    ForEach(0..<viewModel.sequence.count, id: \.self) { i in
                        Circle()
                            .fill(i < viewModel.inputProgress ? Color.success : Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }

    private func cellView(index: Int) -> some View {
        let isHighlighted = viewModel.highlightedCell == index
        let isCorrectTap = viewModel.correctTapIndex == index
        let isWrongTap = viewModel.wrongTapIndex == index
        let isActive = isHighlighted || isCorrectTap

        return RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(cellColors[index].opacity(isActive ? 1.0 : 0.22))
            .frame(height: 140)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isWrongTap ? Color.error :
                        isCorrectTap ? Color.success :
                        isHighlighted ? cellColors[index] :
                        Color.white.opacity(0.08),
                        lineWidth: isActive || isWrongTap ? 3 : 1
                    )
            )
            .shadow(color: isActive ? cellColors[index].opacity(0.5) : .clear, radius: 12)
            .scaleEffect(isWrongTap && !reduceMotion ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isWrongTap)
            .onTapGesture {
                viewModel.playerTapped(index: index)
            }
            .allowsHitTesting(!viewModel.isShowingSequence)
    }

    // MARK: - Result

    private var resultView: some View {
        VStack(spacing: 18) {
            Text("Game Over")
                .font(.gameTitle)
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 10) {
                Text("Level \(displayedScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                    .if(!reduceMotion) { view in
                        view.contentTransition(.numericText())
                    }

                Text("sequence length reached")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)

                Text(viewModel.performanceTier)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tierColor)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .glassCard(cornerRadius: 22)
            .padding(.horizontal, 24)

            GameActionButtons(primaryTint: accentColor) {
                displayedScore = 0
                viewModel.resetGame()
                viewModel.startGame()
            } onSecondary: {
                dismiss()
            }
            .padding(.horizontal, 24)

            Button("Share") {
                ShareService.shareResult(
                    gameType: .sequenceMemory,
                    score: "Level \(viewModel.finalLevel)",
                    percentile: nil
                )
            }
            .font(.caption)
            .foregroundStyle(Color.textSecondary)
            .accessibleTapTarget()
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Helpers

    private var tierColor: Color {
        switch viewModel.performanceTier {
        case "Legendary": return Color(hex: "FFD700")
        case "Exceptional": return accentColor
        case "Solid": return Color.success
        default: return Color.textSecondary
        }
    }

    private func animateScoreCountUp() {
        displayedScore = 0
        let target = viewModel.finalLevel
        guard target > 0 else { return }

        if reduceMotion {
            displayedScore = target
            return
        }

        let totalDuration: Double = 1.2
        let steps = min(target, 30)
        let interval = totalDuration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                withAnimation(.easeOut(duration: 0.05)) {
                    displayedScore = min(step, target)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.05) {
            displayedScore = target
        }
    }
}
