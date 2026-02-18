import SwiftUI

struct ColorSortGameView: View {
    @State private var viewModel: ColorSortViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var timerPulse = false
    @State private var displayedScore: Int = 0

    private let accentColor = Color.accentSecondary

    private let colorNames = ["RED", "BLUE", "GREEN", "YELLOW"]
    private let colorValues: [Color] = [
        Color(hex: "F87171"), // red
        Color(hex: "5B8CFF"), // blue
        Color(hex: "34D399"), // green
        Color(hex: "F59E0B"), // yellow
    ]

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: ColorSortViewModel(config: config))
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

            // Penalty flash overlay
            if viewModel.showPenaltyFlash {
                Color.error.opacity(0.22)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            viewModel.startGame()
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .result = newState {
                animateScoreCountUp()
            }

            if case .active = newState, !reduceMotion {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    timerPulse = true
                }
            } else {
                timerPulse = false
            }
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
                    Color(red: 0.01, green: 0.06, blue: 0.06),
                    Color(red: 0.01, green: 0.02, blue: 0.02)
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
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(accentColor)

            Text("Color Sort")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)

            Text("Tap the ink color, ignore the word!")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Text("15 seconds — Stroop test")
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
        VStack(spacing: 24) {
            // Timer ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 90, height: 90)

                Circle()
                    .trim(from: 0, to: viewModel.timeRemaining / Constants.colorSortDuration)
                    .stroke(
                        viewModel.timeRemaining <= 3 ? Color.error : accentColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(viewModel.timeRemaining <= 3 && timerPulse && !reduceMotion ? 1.08 : 1.0)

                Text(String(format: "%.1f", viewModel.timeRemaining))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(viewModel.timeRemaining <= 3 ? Color.error : Color.textPrimary)
                    .if(!reduceMotion) { view in
                        view.contentTransition(.numericText())
                    }
            }

            Spacer().frame(height: 8)

            // Color word in mismatched ink
            Text(colorNames[viewModel.currentWordIndex])
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(colorValues[viewModel.currentInkIndex])

            // Score counter
            HStack(spacing: 16) {
                Label("\(viewModel.correctCount)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Color.success)
                Label("\(viewModel.wrongCount)", systemImage: "xmark.circle.fill")
                    .foregroundStyle(Color.error)
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))

            Spacer().frame(height: 8)

            // 2x2 answer buttons
            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<4, id: \.self) { index in
                    Button {
                        viewModel.playerTapped(index: index)
                    } label: {
                        Text(colorNames[index])
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibleTapTarget()
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Result

    private var resultView: some View {
        VStack(spacing: 18) {
            Text("Time's Up!")
                .font(.gameTitle)
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 10) {
                Text("\(displayedScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                    .if(!reduceMotion) { view in
                        view.contentTransition(.numericText())
                    }

                Text("correct answers")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)

                if viewModel.correctCount + viewModel.wrongCount > 0 {
                    Text(String(format: "%.0f%% accuracy", viewModel.accuracy))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }

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
                    gameType: .colorSort,
                    score: "\(viewModel.correctCount) correct",
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
        case "Stroop Master": return Color(hex: "FFD700")
        case "Sharp Mind": return accentColor
        case "Getting Warped": return Color.warning
        default: return Color.textSecondary
        }
    }

    private func animateScoreCountUp() {
        displayedScore = 0
        let target = viewModel.correctCount
        guard target > 0 else { return }

        if reduceMotion {
            displayedScore = target
            return
        }

        let totalDuration: Double = 1.5
        let steps = min(target, 60)
        let interval = totalDuration / Double(steps)
        let increment = max(target / steps, 1)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                withAnimation(.easeOut(duration: 0.05)) {
                    displayedScore = min(increment * step, target)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.05) {
            displayedScore = target
        }
    }
}
