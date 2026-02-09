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

    init() {
        self.id = UUID()
        self.totalGamesPlayed = 0
        self.totalWins = 0
    }

    func updateAfterGame(gameType: GameType, score: Double, didWin: Bool) {
        totalGamesPlayed += 1
        if didWin { totalWins += 1 }
        lastPlayedDate = Date()

        switch gameType {
        case .colorFlash, .colorBattle, .reactionDuel, .soundReflex, .vibrationReflex, .dailyChallenge:
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
        }
    }
}
