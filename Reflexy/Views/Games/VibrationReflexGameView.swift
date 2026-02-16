import SwiftUI

struct VibrationReflexGameView: View {
    @State private var viewModel: VibrationReflexViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var activePresses: Set<Int> = []

    @State private var waitingPulse = false
    @State private var activeGlow = false
    @State private var shakeOffset: CGFloat = 0
    @State private var showScoreCard = false

    private let accentPurple = Color(hex: "A855F7")

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: VibrationReflexViewModel(config: config))
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
                    accentPurple.opacity(activeGlow ? 0.4 : 0.2),
                    Color(red: 0.06, green: 0.0, blue: 0.12),
                    .black
                ],
                center: .center,
                startRadius: 30,
                endRadius: 400
            )
            .animation(
                .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
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
                    accentPurple.opacity(0.08),
                    Color(red: 0.04, green: 0.0, blue: 0.08),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.02, blue: 0.1),
                    Color(red: 0.02, green: 0.01, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded {
                viewModel.playerTapped(index: 0)
            }
        )
    }

    // MARK: - Ready

    private var readyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.point.up.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(accentPurple)

            Text("Vibration Reflex")
                .font(.resultTitle)
                .foregroundStyle(.white)

            Text("React to the haptic pulse")
                .font(.bodyLarge)
                .foregroundStyle(.gray)

            Text("No visual cue — feel the vibration")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    // MARK: - Waiting

    private var waitingView: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince1970
            VStack(spacing: 26) {
                ZStack {
                    // Concentric vibration-wave rings
                    ForEach(0..<3, id: \.self) { ring in
                        let phase = (elapsed * 0.8 + Double(ring) * 0.4).truncatingRemainder(dividingBy: 1.5)
                        let scale = 1.0 + phase * 0.6
                        let opacity = max(0, 1.0 - phase / 1.5) * 0.4

                        Circle()
                            .stroke(accentPurple.opacity(opacity), lineWidth: 1.5)
                            .frame(width: 80 * scale, height: 80 * scale)
                    }

                    Image(systemName: "touchid")
                        .font(.system(size: 60))
                        .foregroundStyle(accentPurple.opacity(0.8))
                }

                PulsingText(text: "Feel for the vibration...", color: accentPurple)
            }
        }
    }

    // MARK: - Active

    private var activeView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentPurple.opacity(activeGlow ? 0.3 : 0.1))
                    .frame(width: 160, height: 160)

                Image(systemName: "hand.point.up.fill")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(accentPurple)
                    .scaleEffect(activeGlow ? 1.2 : 1.0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.5)
                            .repeatForever(autoreverses: true),
                        value: activeGlow
                    )
            }

            Text("TAP NOW")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
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
                .foregroundStyle(.white)
                .offset(x: shakeOffset)

            Text("Wait for the vibration before tapping")
                .font(.bodyLarge)
                .foregroundStyle(.gray)

            Button("Try Again") {
                viewModel.resetGame()
                viewModel.startGame()
            }
            .font(.bodyLarge)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(accentPurple)
            .clipShape(Capsule())
            .accessibleTapTarget()
        }
    }

    // MARK: - Multiplayer Panel

    private func playerPanel(index: Int) -> some View {
        let color = Color.playerColor(for: index)

        return ZStack {
            color.opacity(0.05)

            switch viewModel.state {
            case .waiting:
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSince1970
                    ZStack {
                        ForEach(0..<2, id: \.self) { ring in
                            let phase = (elapsed * 0.6 + Double(ring) * 0.5).truncatingRemainder(dividingBy: 1.5)
                            let scale = 1.0 + phase * 0.4
                            let opacity = max(0, 1.0 - phase / 1.5) * 0.3
                            Circle()
                                .stroke(accentPurple.opacity(opacity), lineWidth: 1.5)
                                .frame(width: 50 * scale, height: 50 * scale)
                        }

                        Text("P\(index + 1)")
                            .font(.playerLabel)
                            .foregroundStyle(color)
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
                            .foregroundStyle(accentPurple)
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
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
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

    // MARK: - Result Overlay

    private var resultOverlay: some View {
        ZStack {
            Color.appBackground.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 22) {
                Text("Vibration Reflex")
                    .font(.gameTitle)
                    .foregroundStyle(.gray)

                if viewModel.config.playerMode == .solo {
                    if let ms = viewModel.reactionTimes[0] {
                        VStack(spacing: 8) {
                            Text(Formatters.reactionTime(ms))
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white)

                            Text(viewModel.speedTier)
                                .font(.playerLabel)
                                .foregroundStyle(accentPurple)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(accentPurple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.horizontal, 24)
                        .transition(.scale.combined(with: .opacity))

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
                                Text(Formatters.reactionTime(time))
                                    .font(.bodyLarge)
                                    .monospacedDigit()
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    Button("Play Again") {
                        viewModel.resetGame()
                        viewModel.startGame()
                    }
                    .font(.bodyLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accentPurple)
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

                if viewModel.config.playerMode == .solo {
                    Button("Share") {
                        ShareService.shareResult(
                            gameType: .vibrationReflex,
                            score: Formatters.reactionTime(viewModel.reactionTimes[0] ?? 0),
                            percentile: viewModel.percentile
                        )
                    }
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .accessibleTapTarget()
                }
            }
        }
    }

    // MARK: - Helpers

    private func updateAnimations(for state: GameState) {
        switch state {
        case .waiting:
            waitingPulse = true
            activeGlow = false
            showScoreCard = false
        case .active:
            waitingPulse = false
            activeGlow = true
        case .falseStart:
            activeGlow = false
            triggerShake()
        case .result:
            activeGlow = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showScoreCard = true
            }
        default:
            waitingPulse = false
            activeGlow = false
            showScoreCard = false
        }
    }

    private func triggerShake() {
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

