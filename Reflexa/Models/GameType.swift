import Foundation

enum Difficulty: String, Codable {
    case easy
    case medium
    case hard

    var displayName: String {
        rawValue.capitalized
    }
}

enum GameType: String, CaseIterable, Identifiable, Codable {
    case stopwatch
    case colorFlash
    case quickTap
    case sequenceMemory
    case colorSort
    case gridReaction
    case reactionDuel
    case colorBattle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stopwatch: return "Stopwatch"
        case .colorFlash: return "Color Flash"
        case .quickTap: return "Quick Tap"
        case .sequenceMemory: return "Sequence Memory"
        case .colorSort: return "Color Sort"
        case .gridReaction: return "Grid Reaction"
        case .reactionDuel: return "Reaction Duel"
        case .colorBattle: return "Color Battle"
        }
    }

    var description: String {
        switch self {
        case .stopwatch: return "Stop as close to 0.000 as possible"
        case .colorFlash: return "Tap when the target color matches"
        case .quickTap: return "Tap sprint for 10 seconds"
        case .sequenceMemory: return "Repeat the growing pattern"
        case .colorSort: return "Tap ink color, not the word"
        case .gridReaction: return "Hit lit cells as fast as possible"
        case .reactionDuel: return "Wait for trigger, fastest tap wins"
        case .colorBattle: return "Turn-based color rounds with power-ups"
        }
    }

    var iconName: String {
        switch self {
        case .stopwatch: return "stopwatch.fill"
        case .colorFlash: return "circle.lefthalf.filled"
        case .quickTap: return "hand.tap.fill"
        case .sequenceMemory: return "square.grid.2x2.fill"
        case .colorSort: return "paintpalette.fill"
        case .gridReaction: return "square.grid.3x3.fill"
        case .reactionDuel: return "bolt.fill"
        case .colorBattle: return "flame.fill"
        }
    }

    var difficulty: Difficulty {
        switch self {
        case .quickTap, .colorFlash:
            return .easy
        case .stopwatch, .colorSort, .gridReaction:
            return .medium
        case .sequenceMemory, .reactionDuel, .colorBattle:
            return .hard
        }
    }

    var multiplayerTip: String {
        switch self {
        case .stopwatch:
            return "Each player takes a turn. Closest to zero wins."
        case .gridReaction:
            return "Simultaneous zones. Win rounds by tapping your lit cell first."
        case .reactionDuel:
            return "Wait for trigger. Early tap adds false-start penalty."
        case .colorBattle:
            return "Pass-device rounds with power-ups and penalties."
        default:
            return "Solo mode focuses on your personal best."
        }
    }

    var supportedModes: [PlayerMode] {
        switch self {
        case .stopwatch: return [.solo, .twoPlayer, .fourPlayer]
        case .colorFlash: return [.solo]
        case .quickTap: return [.solo]
        case .sequenceMemory: return [.solo]
        case .colorSort: return [.solo]
        case .gridReaction: return [.solo, .twoPlayer, .fourPlayer]
        case .reactionDuel: return [.twoPlayer, .fourPlayer]
        case .colorBattle: return [.twoPlayer, .fourPlayer]
        }
    }

    var scoreLabel: String {
        switch self {
        case .quickTap: return "taps"
        case .sequenceMemory: return "max level"
        case .colorSort: return "correct answers"
        case .colorFlash, .gridReaction, .reactionDuel: return "reaction time"
        case .stopwatch: return "distance from zero"
        case .colorBattle: return "points"
        }
    }

    var lowerIsBetter: Bool {
        switch self {
        case .quickTap, .sequenceMemory, .colorSort, .colorBattle:
            return false
        default:
            return true
        }
    }

    static let homeGames: [GameType] = [
        .stopwatch, .colorFlash, .quickTap, .sequenceMemory, .colorSort, .gridReaction, .reactionDuel, .colorBattle
    ]
}
