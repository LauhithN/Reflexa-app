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
        ScrollView {
            VStack(spacing: 20) {
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
            .padding(.bottom, 32)
        }
        .background(Color.appBackground.ignoresSafeArea())
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
                                .font(.system(size: 12))
                            Text(game.displayName)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedGame == game ? Color.waiting : Color.cardBackground)
                        .foregroundStyle(selectedGame == game ? .white : .gray)
                        .clipShape(Capsule())
                    }
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
    }

    // MARK: - Personal Best

    private var personalBestCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Personal Best")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text(personalBestText)
                    .font(.resultTitle)
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Games Played")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text("\(filteredResults.count)")
                    .font(.playerLabel)
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .font(.system(size: 40))
                .foregroundStyle(.gray.opacity(0.5))

            Text("No scores yet")
                .font(.playerLabel)
                .foregroundStyle(.gray)

            Text("Play \(selectedGame.displayName) to see your scores here!")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
