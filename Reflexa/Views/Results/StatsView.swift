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
        ScrollView {
            VStack(spacing: 24) {
                lifetimeStatsSection
                recentGamesSection
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Stats")
    }

    // MARK: - Lifetime Stats

    @ViewBuilder
    private var lifetimeStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lifetime Stats")
                .font(.gameTitle)
                .foregroundStyle(.white)

            if let stats {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        StatBadge(
                            label: "Games Played",
                            value: "\(stats.totalGamesPlayed)"
                        )
                        StatBadge(
                            label: "Total Wins",
                            value: "\(stats.totalWins)"
                        )
                        StatBadge(
                            label: "Best Reaction",
                            value: stats.bestReactionTimeMs.map { Formatters.reactionTime($0) } ?? "--"
                        )
                        StatBadge(
                            label: "Best Stopwatch",
                            value: stats.bestStopwatchScore.map { Formatters.stopwatchValue($0) } ?? "--"
                        )
                    }
                }
            } else {
                Text("Play your first game!")
                    .font(.bodyLarge)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
    }

    // MARK: - Recent Games

    @ViewBuilder
    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.gameTitle)
                .foregroundStyle(.white)

            if recentGames.isEmpty {
                Text("No games played yet")
                    .font(.bodyLarge)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(recentGames) { result in
                        gameResultRow(result)
                    }
                }
            }
        }
    }

    // MARK: - Game Result Row

    private func gameResultRow(_ result: GameResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.gameTypeEnum?.displayName ?? result.gameType)
                    .font(.bodyLarge)
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Text(result.playerModeEnum?.displayName ?? result.playerMode)
                        .font(.caption)
                        .foregroundStyle(.gray)

                    Text(Formatters.displayDate(result.timestamp))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Spacer()

            if result.isFalseStart {
                Text("False Start")
                    .font(.playerLabel)
                    .foregroundStyle(Color.error)
            } else if let score = result.scores.first {
                Text(formattedScore(score, gameType: result.gameTypeEnum))
                    .font(.playerLabel)
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
