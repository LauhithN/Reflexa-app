import SwiftUI
import SwiftData

enum LeaderboardTimeScope: String, CaseIterable {
    case allTime = "All Time"
    case thisWeek = "This Week"
    case today = "Today"
}

struct LeaderboardView: View {
    @Query(sort: \GameResult.timestamp, order: .reverse)
    private var allResults: [GameResult]

    @Query private var playerStats: [PlayerStats]

    @State private var selectedGame: GameType = .stopwatch
    @State private var selectedTimeScope: LeaderboardTimeScope = .allTime

    private let leaderboardGames: [GameType] = GameType.allCases.filter {
        $0.supportedModes.contains(.solo)
    }

    private var stats: PlayerStats? { playerStats.first }

    private var filteredResults: [GameResult] {
        let now = Date()
        let calendar = Calendar.current

        return allResults
            .filter { result in
                result.gameType == selectedGame.rawValue
                    && result.playerMode == PlayerMode.solo.rawValue
                    && !result.isFalseStart
                    && passesTimeFilter(result.timestamp, now: now, calendar: calendar)
            }
            .sorted { lhs, rhs in
                let a = lhs.scores.first ?? 0
                let b = rhs.scores.first ?? 0
                return selectedGame.lowerIsBetter ? a < b : a > b
            }
    }

    private func passesTimeFilter(_ date: Date, now: Date, calendar: Calendar) -> Bool {
        switch selectedTimeScope {
        case .allTime: return true
        case .thisWeek: return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .today: return calendar.isDateInToday(date)
        }
    }

    private var personalBestText: String {
        guard let stats else { return "--" }

        switch selectedGame {
        case .stopwatch:
            return stats.bestStopwatchScore.map { selectedGame.formatScore($0) } ?? "--"
        case .quickTap:
            return stats.bestQuickTapCount.map { selectedGame.formatScore(Double($0)) } ?? "--"
        case .gridReaction:
            return stats.bestGridReactionMs.map { selectedGame.formatScore(Double($0)) } ?? "--"
        default:
            return stats.bestReactionTimeMs.map { selectedGame.formatScore(Double($0)) } ?? "--"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                gameModePicker
                timeScopePicker
                personalBestCard

                if filteredResults.isEmpty {
                    emptyState
                } else {
                    entriesList
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 30)
        }
        .background(AmbientBackground())
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Game Mode Picker

    private var gameModePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(leaderboardGames) { game in
                    Button {
                        selectedGame = game
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: game.iconName)
                                .font(.system(size: 12, weight: .bold))

                            Text(game.displayName)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .foregroundStyle(selectedGame == game ? Color.textPrimary : Color.textSecondary)
                        .background(
                            Capsule()
                                .fill(selectedGame == game ? Color.accentPrimary : Color.cardBackground.opacity(0.82))
                                .overlay(
                                    Capsule()
                                        .stroke(selectedGame == game ? .white.opacity(0.18) : Color.strokeSubtle, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(CardButtonStyle())
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Time Scope

    private var timeScopePicker: some View {
        Picker("Time", selection: $selectedTimeScope) {
            ForEach(LeaderboardTimeScope.allCases, id: \.self) { scope in
                Text(scope.rawValue).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .padding(10)
        .background(Color.cardBackground.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.strokeSubtle, lineWidth: 1)
        )
    }

    // MARK: - Personal Best

    private var personalBestCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Personal Best")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                Text(personalBestText)
                    .font(.resultTitle)
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Entries")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                Text("\(filteredResults.count)")
                    .font(.playerLabel.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 18)
    }

    // MARK: - Entries

    private var entriesList: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(filteredResults.prefix(25).enumerated()), id: \.element.id) { rank, result in
                LeaderboardRowView(
                    rank: rank + 1,
                    score: selectedGame.formatScore(result.scores.first ?? 0),
                    date: result.timestamp
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Color.textSecondary.opacity(0.7))

            Text("No scores yet")
                .font(.playerLabel)
                .foregroundStyle(Color.textPrimary)

            Text("Play \(selectedGame.displayName) to create your first leaderboard entry.")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .glassCard(cornerRadius: 18)
    }
}
