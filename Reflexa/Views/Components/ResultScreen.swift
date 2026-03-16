import SwiftUI

struct ResultScreen: View {
    let scores: [PlayerResult]
    let scoreLabel: String
    let gameType: GameType
    let onPlayAgain: () -> Void
    let onHome: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedScore: Double = 0
    @State private var triggerParticles = false

    private var sortedScores: [PlayerResult] {
        scores.sorted { lhs, rhs in
            if lhs.rank == rhs.rank {
                return lhs.score < rhs.score
            }
            return lhs.rank < rhs.rank
        }
    }

    private var isMultiplayer: Bool {
        scores.count > 1
    }

    private var soloResult: PlayerResult? {
        scores.first
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 18) {
                header

                if isMultiplayer {
                    multiplayerLayout
                } else {
                    soloLayout
                }

                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)

            ParticleBurst(trigger: $triggerParticles)
        }
        .onAppear {
            animateResult()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            BrandMark(size: 44, showSparkles: false)

            Text(isMultiplayer ? "Results" : "Your Result")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)

            Text(gameType.displayName)
                .font(.monoSmall)
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    private var soloLayout: some View {
        GlassCard(cornerRadius: 32) {
            VStack(spacing: 16) {
                Text(formattedScore(animatedScore))
                    .font(.monoTime.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)

                Text(scoreLabel.uppercased())
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)

                if soloResult?.isNewBest == true {
                    Text("NEW BEST")
                        .font(.monoSmall)
                        .foregroundStyle(Color.inkPanel)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentAmber)
                        .clipShape(Capsule())
                }

                if let result = soloResult {
                    Text(contextTier(for: result.score))
                        .font(.playerLabel)
                        .foregroundStyle(Color.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var multiplayerLayout: some View {
        VStack(spacing: 18) {
            if let winner = sortedScores.first(where: { $0.isWinner }) {
                Text("\(winner.name) takes it")
                    .font(.resultTitle)
                    .foregroundStyle(winner.color)
                    .lineLimit(1)
            }

            HStack(alignment: .bottom, spacing: 14) {
                ForEach(Array(sortedScores.prefix(4))) { player in
                    podiumBar(for: player)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            GlassCard(cornerRadius: 24) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Rank")
                        Text("Player")
                        Spacer()
                        Text("Score")
                    }
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)

                    ForEach(Array(sortedScores.enumerated()), id: \.element.id) { _, player in
                        HStack(spacing: 10) {
                            Text(medal(for: player.rank))
                                .frame(width: 28, alignment: .leading)

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(player.color)
                                    .frame(width: 8, height: 8)
                                Text(player.name)
                                    .lineLimit(1)
                                    .font(.playerLabel)
                            }

                            Spacer()

                            Text(formattedScore(player.score))
                                .font(.monoSmall)
                                .monospacedDigit()
                                .foregroundStyle(Color.textPrimary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                onPlayAgain()
            } label: {
                Label("Play Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(PrimaryCTAButtonStyle())
            .accessibilityLabel("Play Again")
            .accessibilityHint("Starts another round")

            Button {
                onHome()
            } label: {
                Text("Home")
            }
            .buttonStyle(SecondaryCTAButtonStyle())
            .accessibilityLabel("Home")
            .accessibilityHint("Returns to game list")
        }
    }

    private func animateResult() {
        if isMultiplayer {
            triggerParticles = true
            HapticManager.shared.doublePulse()
            return
        }

        guard let soloResult else { return }

        if reduceMotion {
            animatedScore = soloResult.score
        } else {
            withAnimation(Spring.linear(duration: 0.8)) {
                animatedScore = soloResult.score
            }
        }

        if soloResult.isNewBest {
            triggerParticles = true
            HapticManager.shared.doublePulse()
        }
    }

    private func podiumBar(for player: PlayerResult) -> some View {
        let width: CGFloat = sortedScores.count > 3 ? 72 : 92

        return VStack(spacing: 8) {
            if player.rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.accentAmber)
            } else {
                Spacer()
                    .frame(height: 18)
            }

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [player.color, player.color.opacity(0.58)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: podiumHeight(for: player.rank))
                .overlay(
                    VStack(spacing: 8) {
                        Text(rankTitle(for: player.rank))
                            .font(.playerLabel)
                            .foregroundStyle(Color.inkPanel)

                        Text(formattedScore(player.score))
                            .font(.monoSmall)
                            .monospacedDigit()
                            .foregroundStyle(Color.inkPanel)
                    }
                    .padding(.horizontal, 8)
                )
                .shadow(color: player.color.opacity(0.4), radius: 16, y: 12)

            Text(player.name)
                .font(.playerLabel)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
        }
    }

    private func podiumHeight(for rank: Int) -> CGFloat {
        switch rank {
        case 1: return 210
        case 2: return 162
        case 3: return 126
        default: return 104
        }
    }

    private func rankTitle(for rank: Int) -> String {
        switch rank {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(rank)th"
        }
    }

    private func formattedScore(_ score: Double) -> String {
        switch gameType {
        case .quickTap, .colorSort, .colorBattle:
            return "\(Int(score.rounded()))"
        case .sequenceMemory:
            return "L\(Int(score.rounded()))"
        case .stopwatch:
            return "\(Int(score.rounded()))ms"
        default:
            return "\(Int(score.rounded()))ms"
        }
    }

    private func contextTier(for score: Double) -> String {
        switch gameType {
        case .quickTap:
            switch score {
            case 70...: return "Top 10% • Lightning Fast"
            case 45...: return "Above Average"
            default: return "Keep Training"
            }
        case .sequenceMemory:
            switch score {
            case 12...: return "Top 10% • Memory Ace"
            case 7...: return "Above Average"
            default: return "Keep Training"
            }
        default:
            switch score {
            case ..<220: return "Top 10% • Lightning Fast"
            case ..<320: return "Above Average"
            default: return "Keep Training"
            }
        }
    }

    private func medal(for rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
}
