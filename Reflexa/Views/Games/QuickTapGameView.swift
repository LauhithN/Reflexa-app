import SwiftUI

struct QuickTapGameView: View {
    @State private var viewModel: QuickTapViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var tapBounce = false
    @State private var ringPulse = false
    @State private var timerPulse = false
    @State private var displayedScore: Int = 0

    private let accentGreen = Color.success

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: QuickTapViewModel(config: config))
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
        .overlay {
            if viewModel.state == .waiting || viewModel.state == .active {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if case .active = viewModel.state {
                            triggerTapFeedback()
                        }
                        viewModel.playerTapped(index: 0)
                    }
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
        .gameScaffold(
            title: "Quick Tap",
            gameType: .quickTap,
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
        if case .active = viewModel.state {
            let intensity = min(Double(viewModel.tapCount) / 80.0, 1.0)
            RadialGradient(
                colors: [
                    accentGreen.opacity(0.18 + intensity * 0.36),
                    Color(red: 0.01, green: 0.08 + intensity * 0.07, blue: 0.05),
                    Color(red: 0.01, green: 0.02, blue: 0.02)
                ],
                center: .center,
                startRadius: 20,
                endRadius: 500
            )
        } else if case .result = viewModel.state {
            LinearGradient(
                colors: [
                    accentGreen.opacity(0.18),
                    Color(red: 0.02, green: 0.07, blue: 0.05),
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
            Image(systemName: "bolt.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(accentGreen)

            Text("Quick Tap")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)

            Text("Tap as fast as you can!")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Text("10 seconds to set your record")
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
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 90, height: 90)

                Circle()
                    .trim(from: 0, to: viewModel.timeRemaining / Constants.quickTapDuration)
                    .stroke(
                        viewModel.timeRemaining <= 3 ? Color.error : accentGreen,
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

            Spacer().frame(height: 10)

            ZStack {
                if ringPulse && !reduceMotion {
                    Circle()
                        .stroke(accentGreen.opacity(0.3), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(ringPulse ? 1.6 : 1.0)
                        .opacity(ringPulse ? 0 : 0.8)
                        .animation(.easeOut(duration: 0.5), value: ringPulse)
                }

                Text("\(viewModel.tapCount)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
                    .if(!reduceMotion) { view in
                        view.contentTransition(.numericText())
                    }
                    .scaleEffect(tapBounce && !reduceMotion ? 1.15 : 1.0)
            }

            Text(String(format: "%.1f taps/sec", viewModel.tapsPerSecond))
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(accentGreen.opacity(0.85))
                .if(!reduceMotion) { view in
                    view.contentTransition(.numericText())
                }

            Spacer().frame(height: 20)

            Text("TAP!")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
                .tracking(4)
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

                Text("taps in 10 seconds")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)

                Text(viewModel.speedTier)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(speedTierColor)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .glassCard(cornerRadius: 22)
            .padding(.horizontal, 24)

            Text(String(format: "Best burst: %.1f taps/sec", viewModel.bestTapsPerSecond))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            GameActionButtons(primaryTint: accentGreen) {
                displayedScore = 0
                viewModel.resetGame()
                viewModel.startGame()
            } onSecondary: {
                dismiss()
            }
            .padding(.horizontal, 24)

            Button("Share") {
                ShareService.shareResult(
                    gameType: .quickTap,
                    score: Formatters.tapCount(viewModel.tapCount),
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

    private var speedTierColor: Color {
        switch viewModel.speedTier {
        case "Inhuman": return Color(hex: "FFD700")
        case "Blazing": return accentGreen
        case "Fast": return Color.waiting
        default: return Color.textSecondary
        }
    }

    private func triggerTapFeedback() {
        guard !reduceMotion else { return }

        withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
            tapBounce = true
        }
        ringPulse = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            tapBounce = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            ringPulse = false
        }
    }

    private func animateScoreCountUp() {
        displayedScore = 0
        let target = viewModel.tapCount

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
