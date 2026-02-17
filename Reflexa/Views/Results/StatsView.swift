import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var playerStats: [PlayerStats]
    @Query(sort: \GameResult.timestamp, order: .reverse)
    private var allGames: [GameResult]

    private var recentGames: [GameResult] {
        Array(allGames.prefix(50))
    }

    private var stats: PlayerStats? {
        playerStats.first
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                lifetimeStatsSection
                recentGamesSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 30)
        }
        .background(AmbientBackground())
        .navigationTitle("Stats")
    }

    // MARK: - Lifetime Stats

    @ViewBuilder
    private var lifetimeStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lifetime")
                .font(.sectionTitle)
                .foregroundStyle(Color.textPrimary)

            if let stats {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        summaryValue(title: "Games", value: "\(stats.totalGamesPlayed)")
                        Spacer()
                        summaryValue(title: "Wins", value: "\(stats.totalWins)")
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            StatBadge(label: "Best Reaction", value: stats.bestReactionTimeMs.map { Formatters.reactionTime($0) } ?? "--")
                            StatBadge(label: "Best Stopwatch", value: stats.bestStopwatchScore.map { Formatters.stopwatchValue($0) } ?? "--")
                            StatBadge(label: "Best Grid", value: stats.bestGridReactionMs.map { Formatters.reactionTime($0) } ?? "--")
                            StatBadge(label: "Best Quick Tap", value: stats.bestQuickTapCount.map { Formatters.tapCount($0) } ?? "--")
                        }
                    }
                }
                .padding(16)
                .glassCard(cornerRadius: 18)
            } else {
                Text("Play your first game to generate stats.")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard(cornerRadius: 18)
            }
        }
    }

    private func summaryValue(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            Text(value)
                .font(.resultScore)
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)
        }
    }

    // MARK: - Recent Games

    @ViewBuilder
    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.sectionTitle)
                .foregroundStyle(Color.textPrimary)

            if recentGames.isEmpty {
                Text("No games played yet")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard(cornerRadius: 18)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(recentGames) { result in
                        gameResultRow(result)
                    }
                }
            }
        }
    }

    // MARK: - Game Result Row

    private func gameResultRow(_ result: GameResult) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.gameTypeEnum?.displayName ?? result.gameType)
                    .font(.playerLabel)
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: 8) {
                    Text(result.playerModeEnum?.displayName ?? result.playerMode)
                    Text("•")
                    Text(Formatters.displayDate(result.timestamp))
                }
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            if result.isFalseStart {
                Text("False Start")
                    .font(.playerLabel)
                    .foregroundStyle(Color.error)
            } else if let score = result.scores.first {
                Text(formattedScore(score, gameType: result.gameTypeEnum))
                    .font(.playerLabel.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
        )
    }

    // MARK: - Score Formatting

    private func formattedScore(_ score: Double, gameType: GameType?) -> String {
        guard let gameType else {
            return String(format: "%.0f", score)
        }

        switch gameType {
        case .stopwatch:
            return Formatters.stopwatchValue(score)
        case .quickTap:
            return Formatters.tapCount(Int(score))
        default:
            return Formatters.reactionTime(Int(score))
        }
    }
}
