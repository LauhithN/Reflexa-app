import SwiftUI

struct SoundReflexGameView: View {
    @State private var viewModel: SoundReflexViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activePresses: Set<Int> = []

    @State private var activeGlow = false
    @State private var shakeOffset: CGFloat = 0

    private let accentBlue = Color.waiting

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: SoundReflexViewModel(config: config))
    }

    var body: some View {
        ZStack {
            backgroundView.ignoresSafeArea()

            switch viewModel.config.playerMode {
            case .solo:
                soloContent
            case .twoPlayer:
                TwoPlayerSplitView { index in
                    playerPanel(index: index)
                }
            case .fourPlayer:
                FourPlayerGridView { index in
                    playerPanel(index: index)
                }
            }

            if case .countdown(let value) = viewModel.state {
                CountdownOverlay(value: value)
            }

            if case .result = viewModel.state {
                resultOverlay
            }
        }
        .onAppear {
            viewModel.startGame()
        }
        .onChange(of: viewModel.state) { _, newState in
            activePresses.removeAll()
            updateAnimations(for: newState)
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        switch viewModel.state {
        case .active:
            RadialGradient(
                colors: [
                    accentBlue.opacity(activeGlow && !reduceMotion ? 0.35 : 0.18),
                    Color(red: 0.0, green: 0.03, blue: 0.12),
                    .black
                ],
                center: .center,
                startRadius: 30,
                endRadius: 400
            )
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                value: activeGlow
            )

        case .falseStart:
            LinearGradient(
                colors: [Color.error.opacity(0.4), Color(red: 0.12, green: 0.02, blue: 0.02), .black],
                startPoint: .top,
                endPoint: .bottom
            )

        case .waiting:
            LinearGradient(
                colors: [
                    accentBlue.opacity(0.06),
                    Color(red: 0.01, green: 0.02, blue: 0.08),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        default:
            AmbientBackground()
        }
    }

    // MARK: - Solo Content

    private var soloContent: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .ready:
                readyView

            case .waiting:
                waitingView

            case .active:
                activeView

            case .falseStart:
                falseStartView

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
    }

    // MARK: - Ready

    private var readyView: some View {
        VStack(spacing: 18) {
            Image(systemName: "ear.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(accentBlue)

            Text("Sound Reflex")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)

            Text("React to the audio beep")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Text("No visual cue — listen carefully")
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

    // MARK: - Waiting

    private var waitingView: some View {
        VStack(spacing: 26) {
            if reduceMotion {
                waitingIndicator(phase: 0.8)
            } else {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince1970
                    waitingIndicator(phase: elapsed)
                }
            }

            PulsingText(text: "Listen for the beep...", color: accentBlue)
        }
    }

    private func waitingIndicator(phase: Double) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                let shifted = (phase * 0.7 + Double(ring) * 0.5).truncatingRemainder(dividingBy: 2.0)
                let scale = reduceMotion ? (1.0 + Double(ring) * 0.1) : (1.0 + shifted * 0.5)
                let opacity = reduceMotion ? 0.25 : (max(0, 1.0 - shifted / 2.0) * 0.35)

                Circle()
                    .stroke(accentBlue.opacity(opacity), lineWidth: 1.5)
                    .frame(width: 70 * scale, height: 70 * scale)
            }

            Image(systemName: "ear.fill")
                .font(.system(size: 36))
                .foregroundStyle(accentBlue.opacity(0.85))
        }
    }

    // MARK: - Active

    private var activeView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentBlue.opacity(activeGlow && !reduceMotion ? 0.3 : 0.14))
                    .frame(width: 160, height: 160)

                Image(systemName: "waveform")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(accentBlue)
                    .scaleEffect(activeGlow && !reduceMotion ? 1.15 : 1.0)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.5).repeatForever(autoreverses: true),
                        value: activeGlow
                    )
            }

            Text("TAP NOW")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.textPrimary)
        }
    }

    // MARK: - False Start

    private var falseStartView: some View {
        VStack(spacing: 18) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 46))
                .foregroundStyle(Color.error)

            Text("False Start")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)
                .offset(x: shakeOffset)

            Text("Wait for the beep before tapping")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Button("Try Again") {
                viewModel.resetGame()
                viewModel.startGame()
            }
            .buttonStyle(PrimaryCTAButtonStyle(tint: accentBlue))
            .padding(.horizontal, 28)
            .accessibleTapTarget()
        }
        .padding(22)
        .glassCard(cornerRadius: 24)
        .padding(.horizontal, 16)
    }

    // MARK: - Multiplayer Panel

    private func playerPanel(index: Int) -> some View {
        let color = Color.playerColor(for: index)

        return ZStack {
            color.opacity(0.05)

            switch viewModel.state {
            case .waiting:
                if reduceMotion {
                    waitingPanelCore(index: index, color: color, phase: 0.7)
                } else {
                    TimelineView(.animation) { timeline in
                        let elapsed = timeline.date.timeIntervalSince1970
                        waitingPanelCore(index: index, color: color, phase: elapsed)
                    }
                }

            case .active:
                VStack(spacing: 8) {
                    Text("P\(index + 1)")
                        .font(.playerLabel)
                        .foregroundStyle(color)
                    if viewModel.reactionTimes[index] == nil {
                        Text("TAP!")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(accentBlue)
                    }
                }

            default:
                VStack(spacing: 8) {
                    Text("P\(index + 1)")
                        .font(.playerLabel)
                        .foregroundStyle(color)

                    if let time = viewModel.reactionTimes[index] {
                        Text(Formatters.reactionTime(time))
                            .font(.resultScore)
                            .monospacedDigit()
                            .foregroundStyle(Color.textPrimary)
                    }

                    if case .falseStart(let faulter) = viewModel.state, faulter == index {
                        Text("FALSE START!")
                            .font(.playerLabel)
                            .foregroundStyle(Color.error)
                    }
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !activePresses.contains(index) else { return }
                    activePresses.insert(index)
                    viewModel.playerTapped(index: index)
                }
                .onEnded { _ in
                    activePresses.remove(index)
                }
        )
    }

    private func waitingPanelCore(index: Int, color: Color, phase: Double) -> some View {
        ZStack {
            ForEach(0..<2, id: \.self) { ring in
                let shifted = (phase * 0.6 + Double(ring) * 0.5).truncatingRemainder(dividingBy: 1.5)
                let scale = reduceMotion ? (1.0 + Double(ring) * 0.1) : (1.0 + shifted * 0.4)
                let opacity = reduceMotion ? 0.2 : (max(0, 1.0 - shifted / 1.5) * 0.3)

                Circle()
                    .stroke(accentBlue.opacity(opacity), lineWidth: 1.5)
                    .frame(width: 50 * scale, height: 50 * scale)
            }

            Text("P\(index + 1)")
                .font(.playerLabel)
                .foregroundStyle(color)
        }
    }

    // MARK: - Result Overlay

    private var resultOverlay: some View {
        ZStack {
            Color.appBackground.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Sound Reflex")
                    .font(.gameTitle)
                    .foregroundStyle(Color.textSecondary)

                if viewModel.config.playerMode == .solo {
                    if let ms = viewModel.reactionTimes[0] {
                        VStack(spacing: 8) {
                            Text(Formatters.reactionTime(ms))
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Color.textPrimary)

                            Text(viewModel.speedTier)
                                .font(.playerLabel)
                                .foregroundStyle(accentBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .glassCard(cornerRadius: 22)
                        .padding(.horizontal, 24)

                        PercentileBar(percentile: viewModel.percentile)
                            .padding(.horizontal, 40)
                    }
                } else {
                    if let winner = viewModel.winnerIndex {
                        Text("Player \(winner + 1) Wins!")
                            .font(.resultTitle)
                            .foregroundStyle(Color.playerColor(for: winner))
                    }

                    ForEach(0..<viewModel.config.playerMode.playerCount, id: \.self) { i in
                        HStack {
                            Text("P\(i + 1)")
                                .font(.playerLabel)
                                .foregroundStyle(Color.playerColor(for: i))

                            if let time = viewModel.reactionTimes[i] {
                                Spacer()
                                Text(Formatters.reactionTime(time))
                                    .font(.bodyLarge)
                                    .monospacedDigit()
                                    .foregroundStyle(Color.textPrimary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.cardBackground.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                }

                GameActionButtons(primaryTint: accentBlue) {
                    viewModel.resetGame()
                    viewModel.startGame()
                } onSecondary: {
                    dismiss()
                }
                .padding(.horizontal, 24)

                if viewModel.config.playerMode == .solo {
                    Button("Share") {
                        ShareService.shareResult(
                            gameType: .soundReflex,
                            score: Formatters.reactionTime(viewModel.reactionTimes[0] ?? 0),
                            percentile: viewModel.percentile
                        )
                    }
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .accessibleTapTarget()
                }
            }
        }
    }

    // MARK: - Helpers

    private func updateAnimations(for state: GameState) {
        switch state {
        case .active:
            activeGlow = !reduceMotion

        case .falseStart:
            activeGlow = false
            triggerShake()

        default:
            activeGlow = false
        }
    }

    private func triggerShake() {
        guard !reduceMotion else {
            shakeOffset = 0
            return
        }

        let shakeSequence: [(CGFloat, Double)] = [
            (12, 0.05), (-12, 0.1), (10, 0.15), (-10, 0.2),
            (6, 0.25), (-6, 0.3), (3, 0.35), (0, 0.4)
        ]
        for (offset, delay) in shakeSequence {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: 0.05)) {
                    shakeOffset = offset
                }
            }
        }
    }
}
