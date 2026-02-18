import Foundation
import SwiftData

@Model
final class PlayerStats {
    var id: UUID
    var totalGamesPlayed: Int
    var totalWins: Int
    var bestReactionTimeMs: Int? // Best across all reaction games
    var bestStopwatchScore: Double? // Closest to 0
    var bestQuickTapCount: Int?
    var bestGridReactionMs: Int?
    var lastPlayedDate: Date?
    var currentDailyStreak: Int = 0
    var lastDailyDate: String? // "yyyy-MM-dd" format
    var gamesPlayedTypes: [String] = [] // Track which game types have been played

    init() {
        self.id = UUID()
        self.totalGamesPlayed = 0
        self.totalWins = 0
        self.currentDailyStreak = 0
        self.gamesPlayedTypes = []
    }

    func updateAfterGame(gameType: GameType, score: Double, didWin: Bool) {
        totalGamesPlayed += 1
        if didWin { totalWins += 1 }
        lastPlayedDate = Date()

        // Track game types played
        if !gamesPlayedTypes.contains(gameType.rawValue) {
            gamesPlayedTypes.append(gameType.rawValue)
        }

        switch gameType {
        case .colorFlash, .colorBattle, .reactionDuel, .dailyChallenge:
            let ms = Int(score)
            if let current = bestReactionTimeMs {
                bestReactionTimeMs = min(current, ms)
            } else {
                bestReactionTimeMs = ms
            }
        case .stopwatch:
            if let current = bestStopwatchScore {
                bestStopwatchScore = min(current, score)
            } else {
                bestStopwatchScore = score
            }
        case .quickTap:
            let count = Int(score)
            if let current = bestQuickTapCount {
                bestQuickTapCount = max(current, count)
            } else {
                bestQuickTapCount = count
            }
        case .gridReaction:
            let ms = Int(score)
            if let current = bestGridReactionMs {
                bestGridReactionMs = min(current, ms)
            } else {
                bestGridReactionMs = ms
            }
        case .sequenceMemory, .colorSort:
            break
        }

        // Update daily streak if this is a daily challenge
        if gameType == .dailyChallenge {
            updateDailyStreak()
        }

        // Report achievements to Game Center
        let playedTypesDict = Dictionary(uniqueKeysWithValues: gamesPlayedTypes.compactMap { raw in
            GameType(rawValue: raw).map { ($0, true) }
        })
        GameCenterService.shared.checkAchievements(
            gameType: gameType,
            score: score,
            totalGamesPlayed: totalGamesPlayed,
            gamesPlayedByType: playedTypesDict,
            dailyStreak: currentDailyStreak,
            isFalseStart: false
        )
    }

    private func updateDailyStreak() {
        let todayKey = Date().dailyKey

        if let lastDate = lastDailyDate {
            // Check if yesterday's key matches
            let calendar = Calendar.current
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
                let yesterdayKey = yesterday.dailyKey
                if lastDate == yesterdayKey {
                    currentDailyStreak += 1
                } else if lastDate != todayKey {
                    // Streak broken
                    currentDailyStreak = 1
                }
                // If lastDate == todayKey, don't increment (already played today)
            }
        } else {
            currentDailyStreak = 1
        }

        lastDailyDate = todayKey
    }
}
