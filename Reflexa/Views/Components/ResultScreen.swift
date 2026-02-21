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

            VStack(spacing: 20) {
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

    private var soloLayout: some View {
        VStack(spacing: 14) {
            Text(formattedScore(animatedScore))
                .font(.monoTime)
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)

            Text(scoreLabel)
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            if soloResult?.isNewBest == true {
                Text("✨ New Best!")
                    .font(.playerLabel)
                    .foregroundStyle(Color.appBackground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentAmber)
                    .clipShape(Capsule())
            }

            if let result = soloResult {
                Text(contextTier(for: result.score))
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    private var multiplayerLayout: some View {
        VStack(spacing: 14) {
            if let winner = sortedScores.first(where: { $0.isWinner }) {
                Text("\(winner.name) Wins! 🏆")
                    .font(.resultTitle)
                    .foregroundStyle(winner.color)
                    .lineLimit(1)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Rank")
                    Text("Player")
                    Spacer()
                    Text("Score")
                }
                .font(.monoSmall)
                .foregroundStyle(Color.textSecondary)

                ForEach(Array(sortedScores.enumerated()), id: \.element.id) { index, player in
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
                    .padding(.vertical, 6)
                    .opacity(reduceMotion ? 1 : 0)
                    .animation(reduceMotion ? Spring.gentle : Spring.stagger(index), value: sortedScores.count)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 20)
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
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.cardBackground.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.strokeSubtle, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(CardButtonStyle())
            .accessibilityLabel("Home")
            .accessibilityHint("Returns to game list")
        }
    }

    private func animateResult() {
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

    private func formattedScore(_ score: Double) -> String {
        switch gameType {
        case .quickTap, .colorSort, .colorBattle:
            return "\(Int(score.rounded()))"
        case .sequenceMemory:
            return "L\(Int(score.rounded()))"
        case .stopwatch:
            return Formatters.stopwatchValue(score)
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
