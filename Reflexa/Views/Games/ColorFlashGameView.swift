import SwiftUI

struct ColorFlashGameView: View {
    @State private var viewModel: ColorFlashViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var waitingPulse = false
    @State private var flashGlow = false

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: ColorFlashViewModel(config: config))
    }

    var body: some View {
        ZStack {
            backgroundView.ignoresSafeArea()

            switch viewModel.state {
            case .ready:
                readyView

            case .countdown(let value):
                CountdownOverlay(value: value)

            case .waiting:
                waitingView

            case .active:
                activeView

            case .falseStart:
                falseStartView

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
                        viewModel.playerTapped(index: 0)
                    }
            }
        }
        .onAppear {
            viewModel.startGame()
            updateAnimations(for: viewModel.state)
        }
        .onChange(of: viewModel.state) { _, newState in
            updateAnimations(for: newState)
        }
        .gameScaffold(title: "Color Flash", gameType: .colorFlash) {
            dismiss()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch viewModel.state {
        case .active:
            RadialGradient(
                colors: [
                    Color.white.opacity(flashGlow && !reduceMotion ? 0.95 : 0.72),
                    .red,
                    Color(red: 0.18, green: 0.0, blue: 0.0)
                ],
                center: .center,
                startRadius: 12,
                endRadius: 420
            )
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.2).repeatForever(autoreverses: true),
                value: flashGlow
            )

        case .falseStart:
            LinearGradient(
                colors: [Color.error.opacity(0.55), Color.appBackground],
                startPoint: .top,
                endPoint: .bottom
            )

        case .waiting where viewModel.isDecoyFlashVisible:
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.85),
                    Color.orange.opacity(0.65),
                    Color.appBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        default:
            AmbientBackground()
        }
    }

    private var readyView: some View {
        VStack(spacing: 18) {
            Image(systemName: "scope")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.waiting)

            Text("Color Flash")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)

            Text("Single-moment precision challenge")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Text("Tap only when the full flash appears")
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

    private var waitingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(
                        viewModel.isDecoyFlashVisible ? Color.yellow : Color.waiting.opacity(0.9),
                        lineWidth: 2
                    )
                    .frame(
                        width: waitingPulse && !reduceMotion ? 240 : 170,
                        height: waitingPulse && !reduceMotion ? 240 : 170
                    )

                Circle()
                    .fill(
                        viewModel.isDecoyFlashVisible
                            ? Color.yellow.opacity(0.2)
                            : Color.waiting.opacity(0.15)
                    )
                    .frame(width: 132, height: 132)

                Text(viewModel.isDecoyFlashVisible ? "DECOY" : "HOLD")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.isDecoyFlashVisible ? Color.black : Color.waiting)
            }
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: waitingPulse
            )

            Text("Early tap triggers false start")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            Text("Decoys spotted: \(viewModel.decoyFlashesShown)")
                .font(.caption)
                .foregroundStyle(Color.textSecondary.opacity(0.9))
        }
    }

    private var activeView: some View {
        VStack(spacing: 12) {
            Text("FLASH!")
                .font(.system(size: 58, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("TAP NOW")
                .font(.playerLabel)
                .foregroundStyle(Color.textPrimary.opacity(0.9))
                .tracking(2)
        }
    }

    private var falseStartView: some View {
        VStack(spacing: 18) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 46))
                .foregroundStyle(Color.error)

            Text("False Start")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)

            Text("Wait for the flash before tapping")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Button("Try Again") {
                viewModel.startGame()
            }
            .buttonStyle(PrimaryCTAButtonStyle(tint: .accentPrimary))
            .padding(.horizontal, 28)
            .accessibleTapTarget()
        }
        .padding(22)
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, 16)
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            Text("Precision Result")
                .font(.gameTitle)
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 8) {
                Text(Formatters.reactionTime(viewModel.reactionTimeMs))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)

                Text(speedTitle)
                    .font(.playerLabel)
                    .foregroundStyle(Color.waiting)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .glassCard(cornerRadius: 22)
            .padding(.horizontal, 24)

            PercentileBar(percentile: viewModel.percentile)
                .padding(.horizontal, 40)

            GameActionButtons(primaryTint: .accentPrimary) {
                viewModel.resetGame()
                viewModel.startGame()
            } onSecondary: {
                dismiss()
            }
            .padding(.horizontal, 24)

            Button("Share") {
                ShareService.shareResult(
                    gameType: .colorFlash,
                    score: Formatters.reactionTime(viewModel.reactionTimeMs),
                    percentile: viewModel.percentile
                )
            }
            .font(.caption)
            .foregroundStyle(Color.textSecondary)
            .accessibleTapTarget()
        }
        .padding(.horizontal, 8)
    }

    private var speedTitle: String {
        switch viewModel.reactionTimeMs {
        case ..<170:
            return "Lightning"
        case 170..<220:
            return "Sharp"
        case 220..<280:
            return "Steady"
        default:
            return "Keep Training"
        }
    }

    private func updateAnimations(for state: GameState) {
        switch state {
        case .waiting:
            waitingPulse = !reduceMotion
            flashGlow = false
        case .active:
            waitingPulse = false
            flashGlow = !reduceMotion
        default:
            waitingPulse = false
            flashGlow = false
        }
    }
}
