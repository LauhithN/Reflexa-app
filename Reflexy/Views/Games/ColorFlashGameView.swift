import SwiftUI

struct ColorFlashGameView: View {
    @State private var viewModel: ColorFlashViewModel
    @Environment(\.dismiss) private var dismiss
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
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                viewModel.playerTapped(index: 0)
            }
        )
        .onAppear {
            viewModel.startGame()
            updateAnimations(for: viewModel.state)
        }
        .onChange(of: viewModel.state) { _, newState in
            updateAnimations(for: newState)
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
                    Color.white.opacity(flashGlow ? 0.95 : 0.7),
                    .red,
                    Color(red: 0.18, green: 0.0, blue: 0.0)
                ],
                center: .center,
                startRadius: 12,
                endRadius: 420
            )
            .animation(
                .easeInOut(duration: 0.2).repeatForever(autoreverses: true),
                value: flashGlow
            )
        case .falseStart:
            LinearGradient(
                colors: [Color.error.opacity(0.5), Color.appBackground],
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
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.07, blue: 0.14),
                    Color(red: 0.01, green: 0.02, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var readyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "scope")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.waiting)

            Text("Color Flash")
                .font(.resultTitle)
                .foregroundStyle(.white)

            Text("Single-moment precision challenge")
                .font(.bodyLarge)
                .foregroundStyle(.gray)

            Text("Tap only when the full flash appears")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    private var waitingView: some View {
        VStack(spacing: 26) {
            ZStack {
                Circle()
                    .stroke(
                        viewModel.isDecoyFlashVisible ? Color.yellow : Color.waiting.opacity(0.9),
                        lineWidth: 2
                    )
                    .frame(
                        width: waitingPulse ? 240 : 170,
                        height: waitingPulse ? 240 : 170
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
                .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: waitingPulse
            )

            Text("Early tap triggers false start")
                .font(.caption)
                .foregroundStyle(.gray)

            Text("Decoys spotted: \(viewModel.decoyFlashesShown)")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.9))
        }
    }

    private var activeView: some View {
        VStack(spacing: 12) {
            Text("FLASH!")
                .font(.system(size: 58, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("TAP NOW")
                .font(.playerLabel)
                .foregroundStyle(Color.white.opacity(0.9))
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
                .foregroundStyle(.white)

            Text("Wait for the flash before tapping")
                .font(.bodyLarge)
                .foregroundStyle(.gray)

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
    }

    private var resultView: some View {
        VStack(spacing: 26) {
            Text("Precision Result")
                .font(.gameTitle)
                .foregroundStyle(.gray)

            VStack(spacing: 8) {
                Text(Formatters.reactionTime(viewModel.reactionTimeMs))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(speedTitle)
                    .font(.playerLabel)
                    .foregroundStyle(Color.waiting)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 24)

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
            waitingPulse = true
            flashGlow = false
        case .active:
            waitingPulse = false
            flashGlow = true
        default:
            waitingPulse = false
            flashGlow = false
        }
    }
}
