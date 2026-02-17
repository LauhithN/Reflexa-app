import SwiftUI

struct StopwatchGameView: View {
    @State private var viewModel: StopwatchViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var activePresses: Set<Int> = []

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: StopwatchViewModel(config: config))
    }

    var body: some View {
        ZStack {
            backgroundView.ignoresSafeArea()

            switch viewModel.config.playerMode {
            case .solo:
                soloArena
            case .twoPlayer:
                TwoPlayerSplitView { index in
                    playerPanel(index: index)
                }
            case .fourPlayer:
                FourPlayerGridView { index in
                    playerPanel(index: index)
                }
            }

            // Countdown overlay
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
        .onChange(of: viewModel.state) { _, _ in
            activePresses.removeAll()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    // MARK: - Stage Background

    @ViewBuilder
    private var backgroundView: some View {
        switch viewModel.state {
        case .active:
            RadialGradient(
                colors: [
                    timerColor(for: viewModel.currentValue, stopped: false).opacity(0.45),
                    Color(red: 0.03, green: 0.07, blue: 0.14),
                    Color(red: 0.01, green: 0.02, blue: 0.06)
                ],
                center: .center,
                startRadius: 16,
                endRadius: 460
            )
        case .result:
            LinearGradient(
                colors: [Color.black, Color(red: 0.02, green: 0.03, blue: 0.08)],
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

    // MARK: - Solo Experience

    private var soloArena: some View {
        VStack(spacing: 22) {
            soloHeader

            Spacer(minLength: 18)

            soloPrecisionDial

            VStack(spacing: 8) {
                Text("Tap exactly at 0.00")
                    .font(.playerLabel)
                    .foregroundStyle(.white)

                Text("Lower score is better")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Text("Current pace: \(paceLabel(for: viewModel.currentValue))")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .overlay {
            if viewModel.state == .active {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.playerTapped(index: 0)
                    }
            }
        }
        .ignoresSafeArea()
    }

    private var soloHeader: some View {
        VStack(spacing: 10) {
            Text("Stopwatch Precision")
                .font(.gameTitle)
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                Circle()
                    .fill(headerStatusColor)
                    .frame(width: 8, height: 8)

                Text(headerStatusText)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.35))
            .clipShape(Capsule())
        }
    }

    private var soloPrecisionDial: some View {
        let value = viewModel.currentValue
        let proximity = normalizedProximity(for: value)
        let accent = timerColor(for: value, stopped: false)

        return ZStack {
            Circle()
                .fill(Color.black.opacity(0.28))

            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 14)

            Circle()
                .trim(from: 0, to: proximity)
                .stroke(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.12), value: proximity)

            VStack(spacing: 8) {
                Text(Formatters.stopwatchValue(value))
                    .font(.system(size: 78, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(value >= 0 ? "Before Zero" : "Past Zero")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .frame(width: 290, height: 290)
        .overlay(
            RoundedRectangle(cornerRadius: 145)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Multiplayer Panels

    private func playerPanel(index: Int) -> some View {
        let stopped = viewModel.playerStopped[index]
        let color = Color.playerColor(for: index)
        let score = viewModel.scoreFor(player: index)

        return ZStack {
            LinearGradient(
                colors: [color.opacity(stopped ? 0.16 : 0.28), color.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                if viewModel.config.playerMode != .solo {
                    Text("P\(index + 1)")
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(.gray)
                }

                if stopped, let value = viewModel.stoppedValues[index] {
                    Text(Formatters.stopwatchValue(abs(value)))
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    Text("Score: \(Formatters.stopwatchValue(score))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(timerColor(for: score, stopped: true))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.32))
                        .clipShape(Capsule())
                } else {
                    Text(Formatters.stopwatchValue(viewModel.currentValue))
                        .font(.system(size: 62, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(timerColor(for: viewModel.currentValue, stopped: false))

                    Text("Tap to lock at 0.00")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .padding(14)
        }
        .contentShape(Rectangle())
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
        .accessibilityLabel("Player \(index + 1). \(stopped ? "Stopped" : "Tap to stop")")
    }

    // MARK: - Result

    private var rankedPlayers: [Int] {
        (0..<viewModel.config.playerMode.playerCount).sorted { lhs, rhs in
            viewModel.scoreFor(player: lhs) < viewModel.scoreFor(player: rhs)
        }
    }

    private var soloStoppedValue: Double? {
        viewModel.stoppedValues.indices.contains(0) ? viewModel.stoppedValues[0] : nil
    }

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.84).ignoresSafeArea()

            if viewModel.config.playerMode == .solo {
                soloResultContent
            } else {
                multiplayerResultContent
            }
        }
    }

    private var soloResultContent: some View {
        let score = viewModel.scoreFor(player: 0)

        return VStack(spacing: 22) {
            Text("Stopwatch Result")
                .font(.gameTitle)
                .foregroundStyle(.gray)

            Text(Formatters.stopwatchValue(score))
                .font(.system(size: 74, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            Text(precisionLabel(for: score))
                .font(.playerLabel)
                .foregroundStyle(precisionColor(for: score))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(precisionColor(for: score).opacity(0.18))
                .clipShape(Capsule())

            if let stopped = soloStoppedValue {
                Text("Stopped at \(Formatters.stopwatchValue(stopped))")
                    .font(.caption)
                    .foregroundStyle(.gray)
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
        }
        .padding(.horizontal, 24)
    }

    private var multiplayerResultContent: some View {
        VStack(spacing: 20) {
            Text("Final Stopwatch Board")
                .font(.resultTitle)
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                ForEach(Array(rankedPlayers.enumerated()), id: \.element) { place, player in
                    multiplayerResultRow(player: player, place: place)
                }
            }
            .padding(.horizontal, 24)

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
        }
    }

    private func multiplayerResultRow(player index: Int, place: Int) -> some View {
        let score = viewModel.scoreFor(player: index)
        let winner = viewModel.winnerIndex == index

        return HStack(spacing: 10) {
            Text(place == 0 ? "1st" : place == 1 ? "2nd" : place == 2 ? "3rd" : "\(place + 1)th")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.gray)
                .frame(width: 34, alignment: .leading)

            Text("P\(index + 1)")
                .font(.playerLabel)
                .foregroundStyle(Color.playerColor(for: index))

            Spacer()

            Text(Formatters.stopwatchValue(score))
                .font(.bodyLarge)
                .monospacedDigit()
                .foregroundStyle(winner ? Color.success : .white)

            if winner {
                Text("WINNER")
                    .font(.caption)
                    .foregroundStyle(Color.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.success.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBackground.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - UX Helpers

    private func normalizedProximity(for value: Double) -> CGFloat {
        let clamped = min(abs(value), 8.0)
        let normalized = 1.0 - (clamped / 8.0)
        return CGFloat(max(0.04, normalized))
    }

    private func timerColor(for value: Double, stopped: Bool) -> Color {
        let distance = abs(value)
        if stopped {
            if distance < 0.03 { return .success }
            if distance < 0.10 { return Color.waiting }
            if distance < 0.30 { return .warning }
            return .error
        }
        if distance < 0.2 { return .success }
        if distance < 1.0 { return .warning }
        if value < -2.5 { return .error }
        return .white
    }

    private func paceLabel(for value: Double) -> String {
        let distance = abs(value)
        if distance < 0.2 { return "Near perfect window" }
        if distance < 1.0 { return "Approaching target" }
        if value < 0 { return "Past the target" }
        return "Tracking down to zero"
    }

    private func precisionLabel(for score: Double) -> String {
        switch score {
        case ..<0.03:
            return "Perfect Lock"
        case 0.03..<0.10:
            return "Elite Timing"
        case 0.10..<0.25:
            return "Sharp Stop"
        case 0.25..<0.50:
            return "Close Call"
        default:
            return "Keep Training"
        }
    }

    private func precisionColor(for score: Double) -> Color {
        switch score {
        case ..<0.03:
            return .success
        case 0.03..<0.10:
            return .waiting
        case 0.10..<0.25:
            return .warning
        default:
            return .error
        }
    }

    private var headerStatusText: String {
        switch viewModel.state {
        case .countdown:
            return "Prepare"
        case .active:
            return "Stop On Zero"
        case .result:
            return "Round Complete"
        default:
            return "Precision Mode"
        }
    }

    private var headerStatusColor: Color {
        switch viewModel.state {
        case .active:
            return timerColor(for: viewModel.currentValue, stopped: false)
        case .result:
            return .success
        default:
            return .waiting
        }
    }
}
