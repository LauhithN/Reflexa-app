import Foundation
import SwiftData

@Model
final class GameResult {
    var id: UUID
    var gameType: String
    var playerMode: String
    var scores: [Double] // Score per player (index = player index)
    var winnerIndex: Int? // nil for solo, player index for multiplayer
    var timestamp: Date
    var isFalseStart: Bool

    init(
        gameType: GameType,
        playerMode: PlayerMode,
        scores: [Double],
        winnerIndex: Int? = nil,
        isFalseStart: Bool = false
    ) {
        self.id = UUID()
        self.gameType = gameType.rawValue
        self.playerMode = playerMode.rawValue
        self.scores = scores
        self.winnerIndex = winnerIndex
        self.timestamp = Date()
        self.isFalseStart = isFalseStart
    }

    var gameTypeEnum: GameType? {
        GameType(rawValue: gameType)
    }

    var playerModeEnum: PlayerMode? {
        PlayerMode(rawValue: playerMode)
    }
}
