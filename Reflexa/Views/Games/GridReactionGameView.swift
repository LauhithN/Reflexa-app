import SwiftUI

struct GridReactionGameView: View {
    @State private var viewModel: GridReactionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var cellScales: [CGFloat] = Array(repeating: 1.0, count: 16)
    @State private var cellShakes: [CGFloat] = Array(repeating: 0, count: 16)
    @State private var displayedAverage: Int = 0
    @State private var roundRevealCount: Int = 0

    private let accentAmber = Color.warning

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: GridReactionViewModel(config: config))
    }

    var body: some View {
        ZStack {
            backgroundView.ignoresSafeArea()

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
        .onChange(of: viewModel.activeCell) { _, newValue in
            guard let cell = newValue else { return }
            guard !reduceMotion else {
                cellScales[cell] = 1.0
                return
            }

            cellScales[cell] = 0.85
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                cellScales[cell] = 1.0
            }
        }
        .onChange(of: viewModel.lastTapCellIndex) { _, newValue in
            guard let cell = newValue, let correct = viewModel.lastTapCorrect else { return }

            if correct {
                guard !reduceMotion else {
                    cellScales[cell] = 1.0
                    return
                }

                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                    cellScales[cell] = 0.85
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                        cellScales[cell] = 1.0
                    }
                }
            } else {
                triggerCellShake(cell)
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .result = newState {
                animateResultReveal()
            }
        }
        .gameScaffold(
            title: "Grid Reaction",
            gameType: .gridReaction,
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
        switch viewModel.state {
        case .waiting, .active:
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.0),
                    Color(red: 0.03, green: 0.02, blue: 0.0),
                    Color(red: 0.01, green: 0.01, blue: 0.01)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .result:
            LinearGradient(
                colors: [
                    accentAmber.opacity(0.14),
                    Color(red: 0.05, green: 0.04, blue: 0.0),
                    Color(red: 0.01, green: 0.01, blue: 0.01)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        default:
            AmbientBackground()
        }
    }

    // MARK: - Ready

    private var readyView: some View {
        VStack(spacing: 18) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(accentAmber)

            Text("Grid Reaction")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)

            Text("Tap the lit square as fast as you can")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Text("\(Constants.gridReactionRounds) rounds")
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

    // MARK: - Game View

    private var gameView: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Text("Round \(viewModel.currentRound) / \(Constants.gridReactionRounds)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .if(!reduceMotion) { view in
                        view.contentTransition(.numericText())
                    }

                HStack(spacing: 3) {
                    ForEach(0..<Constants.gridReactionRounds, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(i < viewModel.roundTimes.count ? accentAmber : Color.white.opacity(0.12))
                            .frame(height: 5)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer().frame(height: 6)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: viewModel.gridSize),
                spacing: 8
            ) {
                ForEach(0..<(viewModel.gridSize * viewModel.gridSize), id: \.self) { cellIndex in
                    gridCell(cellIndex)
                }
            }
            .padding(.horizontal, 16)

            Spacer().frame(height: 8)

            if let lastTime = viewModel.roundTimes.last {
                Text(Formatters.reactionTime(lastTime))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(lastTimeColor(lastTime))
                    .if(!reduceMotion) { view in
                        view.transition(.move(edge: .bottom).combined(with: .opacity))
                            .contentTransition(.numericText())
                    }
            }

            if viewModel.wrongTapCount > 0 {
                Text("Wrong taps: \(viewModel.wrongTapCount)")
                    .font(.caption)
                    .foregroundStyle(Color.error.opacity(0.78))
            }
        }
    }

    private func gridCell(_ cellIndex: Int) -> some View {
        let isActive = viewModel.activeCell == cellIndex
        let feedbackColor = cellFeedbackColor(cellIndex)

        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(feedbackColor ?? (isActive ? accentAmber : Color.cardBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
                .if(isActive) { view in
                    view.shadow(color: accentAmber.opacity(0.55), radius: 12)
                }
        }
        .aspectRatio(1, contentMode: .fit)
        .scaleEffect(cellScales[cellIndex])
        .offset(x: cellShakes[cellIndex])
        .onTapGesture {
            viewModel.cellTapped(cellIndex)
        }
        .accessibilityLabel("Cell \(cellIndex + 1). \(isActive ? "Active, tap now" : "Inactive")")
    }

    private func cellFeedbackColor(_ cellIndex: Int) -> Color? {
        guard viewModel.lastTapCellIndex == cellIndex, let correct = viewModel.lastTapCorrect else {
            return nil
        }
        return correct ? Color.success : Color.error
    }

    private func lastTimeColor(_ ms: Int) -> Color {
        switch ms {
        case ..<300: return Color.success
        case 300..<500: return Color.textPrimary
        default: return Color.error
        }
    }

    // MARK: - Result

    private var resultView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Text("Grid Reaction")
                    .font(.gameTitle)
                    .foregroundStyle(Color.textSecondary)

                VStack(spacing: 10) {
                    Text("Average")
                        .font(.bodyLarge)
                        .foregroundStyle(Color.textSecondary)

                    Text(Formatters.reactionTime(displayedAverage))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.textPrimary)
                        .if(!reduceMotion) { view in
                            view.contentTransition(.numericText())
                        }

                    Text(viewModel.speedTier)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentAmber)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .glassCard(cornerRadius: 22)
                .padding(.horizontal, 24)

                if let fastest = viewModel.fastestRoundMs, let slowest = viewModel.slowestRoundMs {
                    HStack(spacing: 20) {
                        statPill("Fastest", value: "\(fastest)ms", color: Color.success)
                        statPill("Slowest", value: "\(slowest)ms", color: Color.error)
                        statPill("Wrong", value: "\(viewModel.wrongTapCount)", color: viewModel.wrongTapCount > 0 ? Color.error : Color.textSecondary)
                    }
                    .padding(.horizontal, 24)
                }

                PercentileBar(percentile: viewModel.percentile)
                    .padding(.horizontal, 40)

                VStack(spacing: 6) {
                    ForEach(Array(viewModel.roundTimes.enumerated()), id: \.offset) { index, time in
                        if index < roundRevealCount {
                            roundRow(index: index, time: time)
                                .if(!reduceMotion) { view in
                                    view.transition(.opacity.combined(with: .move(edge: .leading)))
                                }
                        }
                    }
                }
                .padding(.horizontal, 24)

                GameActionButtons(primaryTint: accentAmber) {
                    displayedAverage = 0
                    roundRevealCount = 0
                    viewModel.resetGame()
                    viewModel.startGame()
                } onSecondary: {
                    dismiss()
                }
                .padding(.horizontal, 24)

                Button("Share") {
                    ShareService.shareResult(
                        gameType: .gridReaction,
                        score: Formatters.reactionTime(viewModel.averageTimeMs),
                        percentile: viewModel.percentile
                    )
                }
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .accessibleTapTarget()

                Spacer().frame(height: 20)
            }
            .padding(.top, 20)
        }
    }

    private func statPill(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
        )
    }

    private func roundRow(index: Int, time: Int) -> some View {
        let maxTime = viewModel.roundTimes.max() ?? 1
        let barWidth = CGFloat(time) / CGFloat(maxTime)

        return HStack(spacing: 10) {
            Text("R\(index + 1)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 28, alignment: .leading)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(lastTimeColor(time).opacity(0.72))
                    .frame(width: geo.size.width * barWidth)
            }
            .frame(height: 14)

            Text(Formatters.reactionTime(time))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(lastTimeColor(time))
                .frame(width: 55, alignment: .trailing)
        }
    }

    // MARK: - Helpers

    private func triggerCellShake(_ cellIndex: Int) {
        guard !reduceMotion else { return }

        let shakeSequence: [(CGFloat, Double)] = [
            (8, 0.03), (-8, 0.06), (6, 0.09), (-6, 0.12),
            (3, 0.15), (0, 0.18)
        ]
        for (offset, delay) in shakeSequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: 0.03)) {
                    cellShakes[cellIndex] = offset
                }
            }
        }
    }

    private func animateResultReveal() {
        let target = viewModel.averageTimeMs

        if reduceMotion {
            displayedAverage = target
            roundRevealCount = viewModel.roundTimes.count
            return
        }

        let totalDuration: Double = 1.2
        let steps = 40
        let interval = totalDuration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                withAnimation(.easeOut(duration: 0.03)) {
                    displayedAverage = Int(Double(target) * Double(step) / Double(steps))
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.05) {
            displayedAverage = target
        }

        let roundCount = viewModel.roundTimes.count
        for i in 0..<roundCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8 + Double(i) * 0.08) {
                withAnimation(.easeOut(duration: 0.2)) {
                    roundRevealCount = i + 1
                }
            }
        }
    }
}
