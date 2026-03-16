import Foundation

struct GameConfiguration {
    let gameType: GameType
    let playerMode: PlayerMode
    let playStyle: GamePlayStyle
    let playerNames: [String]

    init(
        gameType: GameType,
        playerMode: PlayerMode,
        playStyle: GamePlayStyle? = nil,
        playerNames: [String] = ["Player 1", "Player 2", "Player 3", "Player 4"]
    ) {
        self.gameType = gameType
        self.playerMode = playerMode
        self.playStyle = playStyle ?? gameType.defaultPlayStyle
        let trimmed = playerNames.map { name in
            let value = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? "Player" : value
        }

        var normalized = Array(trimmed.prefix(4))
        while normalized.count < 4 {
            normalized.append("Player \(normalized.count + 1)")
        }
        self.playerNames = normalized
    }

    var activePlayerNames: [String] {
        Array(playerNames.prefix(playerMode.playerCount)).enumerated().map { index, name in
            name.isEmpty ? "Player \(index + 1)" : name
        }
    }

    var roundCount: Int {
        switch gameType {
        case .gridReaction:
            return Constants.gridReactionRounds
        case .reactionDuel:
            return Constants.reactionDuelRounds
        case .colorBattle:
            return playerMode == .twoPlayer ? Constants.colorBattle2PRounds : Constants.colorBattle4PRounds
        case .colorFlash, .colorSort:
            return 10
        case .stopwatch, .quickTap, .sequenceMemory:
            return 1
        }
    }

    var requiresPassDevice: Bool {
        playerMode != .solo && effectivePlayStyle == .turnBased
    }

    var isTurnBased: Bool {
        playerMode != .solo && effectivePlayStyle == .turnBased
    }

    var effectivePlayStyle: GamePlayStyle {
        playerMode == .solo ? .simultaneous : playStyle
    }
}
