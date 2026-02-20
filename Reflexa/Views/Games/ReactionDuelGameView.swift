import SwiftUI

struct ReactionDuelGameView: View {
    @State private var viewModel: ReactionDuelViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var activePresses: Set<Int> = []

    init(config: GameConfiguration) {
        _viewModel = State(initialValue: ReactionDuelViewModel(config: config))
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

            if case .countdown(let value) = viewModel.state {
                CountdownOverlay(value: value)
            }

            VStack {
                headerView
                Spacer()
            }
            .padding(.top, 10)

            if case .result = viewModel.state {
                resultOverlay
            }
        }
        .onAppear {
            viewModel.startGame()
        }
        .onChange(of: viewModel.state) { _, newState in
            if newState != .active {
                activePresses.removeAll()
            }
        }
        .gameScaffold(title: "Charge & Release", gameType: .reactionDuel) {
            dismiss()
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    // MARK: - Stage

    @ViewBuilder
    private var backgroundView: some View {
        switch viewModel.state {
        case .active:
            RadialGradient(
                colors: [
                    Color.success.opacity(0.25),
                    Color(red: 0.02, green: 0.12, blue: 0.2),
                    Color(red: 0.01, green: 0.03, blue: 0.08)
                ],
                center: .center,
                startRadius: 16,
                endRadius: 460
            )
        case .falseStart:
            LinearGradient(
                colors: [Color.error.opacity(0.6), Color.black],
                startPoint: .top,
                endPoint: .bottom
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

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Charge & Release")
                .font(.gameTitle)
                .foregroundStyle(.white)

            Text("Target \(percent(viewModel.targetCharge)) • Perfect ±3%")
                .font(.caption)
                .foregroundStyle(.gray)

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
            .background(Color.black.opacity(0.32))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
    }

    private var soloArena: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 84)

            playerPanel(index: 0)
                .frame(maxWidth: 440)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.28), radius: 18, y: 8)

            Text("Solo precision run")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.28))
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Player Panel

    private func playerPanel(index: Int) -> some View {
        let color = Color.playerColor(for: index)
        let charge = viewModel.chargeValues[index]
        let lockedCharge = viewModel.lockedCharges[index]
        let score = viewModel.roundScores[index]
        let reaction = viewModel.reactionTimes[index]
        let charging = viewModel.chargingStates[index]
        let isWinner = viewModel.winnerIndex == index && viewModel.state == .result

        return ZStack {
            LinearGradient(
                colors: [color.opacity(0.28), color.opacity(0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Circle()
                        .fill(panelStatusColor(for: index))
                        .frame(width: 10, height: 10)

                    Text(viewModel.config.playerMode == .solo ? "SOLO" : "PLAYER \(index + 1)")
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(.gray)

                    Spacer()

                    if isWinner {
                        Text("WINNER")
                            .font(.caption)
                            .foregroundStyle(Color.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.success.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }

                Text(percent(lockedCharge ?? charge))
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(lockedCharge == nil ? .white : qualityColor(for: score))

                chargeMeter(value: charge, color: color, locked: lockedCharge != nil)

                if let score {
                    Text("Offset \(String(format: "%.1f", score))%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(qualityColor(for: score))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                }

                if let reaction {
                    Text("Start \(Formatters.reactionTime(reaction))")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Text(panelStatusText(for: index, charging: charging, locked: lockedCharge != nil))
                    .font(.caption)
                    .foregroundStyle(.gray)

                if case .falseStart(let faulter) = viewModel.state, faulter == index {
                    Text("FALSE START")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.error)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.error.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(16)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(pressGesture(for: index))
    }

    private func chargeMeter(value: Double, color: Color, locked: Bool) -> some View {
        GeometryReader { geo in
            let progress = CGFloat(min(max(value / 100, 0), 1))
            let zoneStart = CGFloat(viewModel.perfectWindow.lowerBound / 100)
            let zoneWidth = CGFloat((viewModel.perfectWindow.upperBound - viewModel.perfectWindow.lowerBound) / 100)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))

                Capsule()
                    .fill(Color.success.opacity(0.3))
                    .frame(width: geo.size.width * zoneWidth)
                    .offset(x: geo.size.width * zoneStart)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.45)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress)
            }
            .opacity(locked ? 0.92 : 1)
        }
        .frame(height: 12)
    }

    private func pressGesture(for index: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !activePresses.contains(index) else { return }
                activePresses.insert(index)
                viewModel.playerPressBegan(index: index)
            }
            .onEnded { _ in
                let wasPressed = activePresses.remove(index) != nil
                if wasPressed {
                    viewModel.playerPressEnded(index: index)
                }
            }
    }

    // MARK: - Result

    private var rankedPlayers: [Int] {
        (0..<viewModel.config.playerMode.playerCount).sorted { lhs, rhs in
            let lhsScore = viewModel.roundScores[lhs] ?? Double.greatestFiniteMagnitude
            let rhsScore = viewModel.roundScores[rhs] ?? Double.greatestFiniteMagnitude
            if lhsScore == rhsScore {
                let lhsReaction = viewModel.reactionTimes[lhs] ?? Int.max
                let rhsReaction = viewModel.reactionTimes[rhs] ?? Int.max
                return lhsReaction < rhsReaction
            }
            return lhsScore < rhsScore
        }
    }

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.86).ignoresSafeArea()

            if let falseStartPlayer = viewModel.falseStartPlayer {
                falseStartResultOverlay(player: falseStartPlayer)
            } else {
                standardResultOverlay
            }
        }
    }

    private var standardResultOverlay: some View {
        VStack(spacing: 20) {
            if let winner = viewModel.winnerIndex {
                Text("Player \(winner + 1) Wins!")
                    .font(.resultTitle)
                    .foregroundStyle(Color.playerColor(for: winner))
            }

            Text("Final Charge Board")
                .font(.caption)
                .foregroundStyle(.gray)

            VStack(spacing: 10) {
                ForEach(Array(rankedPlayers.enumerated()), id: \.element) { place, playerIndex in
                    resultRow(player: playerIndex, place: place)
                }
            }
            .padding(.horizontal, 24)

            resultActions
        }
        .padding(.top, 24)
    }

    private func falseStartResultOverlay(player: Int) -> some View {
        VStack(spacing: 20) {
            if let winner = viewModel.winnerIndex {
                Text("Player \(winner + 1) Wins!")
                    .font(.resultTitle)
                    .foregroundStyle(Color.playerColor(for: winner))
            }

            Text("Player \(player + 1) false started before the signal.")
                .font(.bodyLarge)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            resultActions
        }
        .padding(.top, 24)
    }

    private var resultActions: some View {
        GameActionButtons(primaryTint: .accentPrimary) {
            viewModel.resetGame()
            viewModel.startGame()
        } onSecondary: {
            dismiss()
        }
    }

    private func resultRow(player index: Int, place: Int) -> some View {
        let score = viewModel.roundScores[index] ?? Double.greatestFiniteMagnitude
        let charge = viewModel.lockedCharges[index] ?? 0

        return HStack(spacing: 10) {
            Text(placeLabel(for: place))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.gray)
                .frame(width: 34, alignment: .leading)

            Text("P\(index + 1)")
                .font(.playerLabel)
                .foregroundStyle(Color.playerColor(for: index))

            Spacer()

            Text(percent(charge))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.gray)

            Text("\(String(format: "%.1f", score))%")
                .font(.bodyLarge)
                .monospacedDigit()
                .foregroundStyle(qualityColor(for: score))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cardBackground.opacity(0.86))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private var headerStatusText: String {
        switch viewModel.state {
        case .countdown:
            return "Prepare"
        case .waiting:
            return "Wait For Signal"
        case .active:
            return "Hold, Then Release"
        case .falseStart:
            return "False Start"
        case .result:
            return "Round Complete"
        default:
            return "Precision Duel"
        }
    }

    private var headerStatusColor: Color {
        switch viewModel.state {
        case .active:
            return .success
        case .falseStart:
            return .error
        default:
            return .waiting
        }
    }

    private func panelStatusText(for index: Int, charging: Bool, locked: Bool) -> String {
        switch viewModel.state {
        case .waiting:
            return "Hold only after GO"
        case .active:
            if locked { return "Locked in" }
            if charging { return "Charging... release in green zone" }
            return "Press and hold to charge"
        case .falseStart(let faulter):
            return faulter == index ? "Started too early" : "Win by opponent fault"
        case .result:
            return viewModel.winnerIndex == index ? "Best precision" : "Round complete"
        default:
            return "Ready"
        }
    }

    private func panelStatusColor(for index: Int) -> Color {
        if case .falseStart(let faulter) = viewModel.state, faulter == index {
            return .error
        }
        if viewModel.winnerIndex == index, viewModel.state == .result {
            return .success
        }
        switch viewModel.state {
        case .active:
            return viewModel.chargingStates[index] ? .warning : .success
        case .waiting:
            return .warning
        default:
            return .gray
        }
    }

    private func qualityColor(for score: Double?) -> Color {
        guard let score else { return .white }
        switch score {
        case ..<1.8:
            return .success
        case 1.8..<4.0:
            return Color.waiting
        case 4.0..<7.0:
            return .warning
        default:
            return .error
        }
    }

    private func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    private func placeLabel(for place: Int) -> String {
        switch place {
        case 0: return "1st"
        case 1: return "2nd"
        case 2: return "3rd"
        default: return "\(place + 1)th"
        }
    }
}
