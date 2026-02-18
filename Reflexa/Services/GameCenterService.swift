import GameKit
import SwiftUI

/// Game Center integration service — handles authentication, leaderboards, and achievements.
/// Works gracefully without an Apple Developer account (authentication simply fails silently).
@Observable
final class GameCenterService {
    static let shared = GameCenterService()

    private(set) var isAuthenticated = false
    private(set) var authError: String?

    private init() {}

    // MARK: - Authentication

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if let error {
                    self?.isAuthenticated = false
                    self?.authError = error.localizedDescription
                    return
                }

                // Skip presenting login UI automatically — user can trigger from Game Center button
                if viewController != nil {
                    self?.isAuthenticated = false
                    return
                }

                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self?.authError = nil
            }
        }
    }

    // MARK: - Leaderboards

    /// Leaderboard IDs for each solo game mode
    enum LeaderboardID {
        static let stopwatchBest = "reflexa.stopwatch.best"
        static let colorFlashBest = "reflexa.colorflash.best"
        static let quickTapBest = "reflexa.quicktap.best"
        static let sequenceMemoryBest = "reflexa.sequencememory.best"
        static let colorSortBest = "reflexa.colorsort.best"
        static let gridReactionBest = "reflexa.gridreaction.best"
        static let dailyChallengeBest = "reflexa.dailychallenge.best"
    }

    /// Returns the leaderboard ID for a given game type (nil for multiplayer-only games)
    static func leaderboardID(for gameType: GameType) -> String? {
        switch gameType {
        case .stopwatch: return LeaderboardID.stopwatchBest
        case .colorFlash: return LeaderboardID.colorFlashBest
        case .quickTap: return LeaderboardID.quickTapBest
        case .sequenceMemory: return LeaderboardID.sequenceMemoryBest
        case .colorSort: return LeaderboardID.colorSortBest
        case .gridReaction: return LeaderboardID.gridReactionBest
        case .dailyChallenge: return LeaderboardID.dailyChallengeBest
        case .colorBattle, .reactionDuel: return nil
        }
    }

    /// Submit a score to Game Center leaderboard
    func submitScore(_ score: Int, for gameType: GameType) {
        guard isAuthenticated else { return }
        guard let leaderboardID = Self.leaderboardID(for: gameType) else { return }

        Task {
            try? await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
        }
    }

    // MARK: - Achievements

    enum AchievementID {
        static let firstGame = "reflexa.first_game"
        static let tenGames = "reflexa.ten_games"
        static let hundredGames = "reflexa.hundred_games"
        static let sub200ms = "reflexa.sub_200ms"
        static let sub150ms = "reflexa.sub_150ms"
        static let perfectStopwatch = "reflexa.perfect_stopwatch"
        static let dailyStreak7 = "reflexa.daily_streak_7"
        static let dailyStreak30 = "reflexa.daily_streak_30"
        static let allGamesPlayed = "reflexa.all_games_played"
        static let quickTap100 = "reflexa.quick_tap_100"
    }

    /// Report an achievement as fully completed
    func reportAchievement(id: String, percentComplete: Double = 100.0) {
        guard isAuthenticated else { return }

        Task {
            let achievement = GKAchievement(identifier: id)
            achievement.percentComplete = percentComplete
            achievement.showsCompletionBanner = true
            try? await GKAchievement.report([achievement])
        }
    }

    /// Check and report achievements after a game result
    func checkAchievements(
        gameType: GameType,
        score: Double,
        totalGamesPlayed: Int,
        gamesPlayedByType: [GameType: Bool],
        dailyStreak: Int,
        isFalseStart: Bool
    ) {
        guard isAuthenticated, !isFalseStart else { return }

        // Game count achievements
        if totalGamesPlayed >= 1 {
            reportAchievement(id: AchievementID.firstGame)
        }
        if totalGamesPlayed >= 10 {
            reportAchievement(id: AchievementID.tenGames)
        }
        if totalGamesPlayed >= 100 {
            reportAchievement(id: AchievementID.hundredGames)
        }

        // Reaction time achievements (for reaction-based games)
        let reactionMs = Int(score)
        switch gameType {
        case .colorFlash, .dailyChallenge:
            if reactionMs < 200 {
                reportAchievement(id: AchievementID.sub200ms)
            }
            if reactionMs < 150 {
                reportAchievement(id: AchievementID.sub150ms)
            }
        default:
            break
        }

        // Stopwatch perfection
        if gameType == .stopwatch && abs(score) < 0.005 {
            reportAchievement(id: AchievementID.perfectStopwatch)
        }

        // Quick Tap 100+
        if gameType == .quickTap && Int(score) >= 100 {
            reportAchievement(id: AchievementID.quickTap100)
        }

        // Daily streak achievements
        if dailyStreak >= 7 {
            reportAchievement(id: AchievementID.dailyStreak7)
        }
        if dailyStreak >= 30 {
            reportAchievement(id: AchievementID.dailyStreak30)
        }

        // All games played
        if gamesPlayedByType.count >= GameType.allCases.count {
            reportAchievement(id: AchievementID.allGamesPlayed)
        }
    }

    // MARK: - UI

    /// Show Game Center dashboard (only when authenticated)
    func showDashboard(state: GKGameCenterViewControllerState = .default) {
        guard isAuthenticated else { return }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        let gcVC = GKGameCenterViewController(state: state)
        gcVC.gameCenterDelegate = GameCenterDismissHandler.shared
        rootVC.present(gcVC, animated: true)
    }
}

/// Helper to handle Game Center view controller dismissal
final class GameCenterDismissHandler: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismissHandler()
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
