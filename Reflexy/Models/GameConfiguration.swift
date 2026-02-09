import Foundation

struct GameConfiguration {
    let gameType: GameType
    let playerMode: PlayerMode

    var roundCount: Int {
        switch gameType {
        case .colorBattle:
            return playerMode == .twoPlayer ? Constants.colorBattle2PRounds : Constants.colorBattle4PRounds
        case .gridReaction:
            return Constants.gridReactionRounds
        default:
            return 1
        }
    }

    var isBestOf: Bool {
        gameType == .colorBattle
    }

    var majorityNeeded: Int {
        (roundCount / 2) + 1
    }
}
