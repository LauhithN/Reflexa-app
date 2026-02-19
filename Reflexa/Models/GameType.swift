import Foundation

enum GameType: String, CaseIterable, Identifiable, Codable {
    case stopwatch
    case colorFlash
    case colorBattle
    case reactionDuel
    case dailyChallenge
    case quickTap
    case sequenceMemory
    case colorSort
    case gridReaction

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stopwatch: return "Stopwatch"
        case .colorFlash: return "Color Flash"
        case .colorBattle: return "Color Battle"
        case .reactionDuel: return "Charge & Release"
        case .dailyChallenge: return "Daily Challenge"
        case .quickTap: return "Quick Tap"
        case .sequenceMemory: return "Sequence Memory"
        case .colorSort: return "Color Sort"
        case .gridReaction: return "Grid Reaction"
        }
    }

    var description: String {
        switch self {
        case .stopwatch: return "Stop at exactly 0"
        case .colorFlash: return "Ignore decoys, tap true flash"
        case .colorBattle: return "Power rounds and penalties"
        case .reactionDuel: return "Hold, charge, release on target"
        case .dailyChallenge: return "One shot per day"
        case .quickTap: return "Tap as fast as you can"
        case .sequenceMemory: return "Repeat the sequence"
        case .colorSort: return "Tap the color, not the word"
        case .gridReaction: return "Tap the lit square"
        }
    }

    var supportedModes: [PlayerMode] {
        switch self {
        case .stopwatch: return [.solo, .twoPlayer, .fourPlayer]
        case .colorFlash: return [.solo]
        case .colorBattle: return [.twoPlayer, .fourPlayer]
        case .reactionDuel: return [.solo, .twoPlayer, .fourPlayer]
        case .dailyChallenge: return [.solo]
        case .quickTap: return [.solo]
        case .sequenceMemory: return [.solo]
        case .colorSort: return [.solo]
        case .gridReaction: return [.solo]
        }
    }

    /// Whether lower score is better for this game type
    var lowerIsBetter: Bool {
        switch self {
        case .quickTap, .sequenceMemory, .colorSort: return false
        default: return true
        }
    }

    /// Format a score for display in stats and results
    func formatScore(_ score: Double) -> String {
        switch self {
        case .stopwatch:
            return Formatters.stopwatchValue(score)
        case .quickTap:
            return Formatters.tapCount(Int(score))
        case .sequenceMemory:
            return "Level \(Int(score))"
        case .colorSort:
            return "\(Int(score)) correct"
        default:
            return Formatters.reactionTime(Int(score))
        }
    }

    var iconName: String {
        switch self {
        case .stopwatch: return "bolt.circle.fill"
        case .colorFlash: return "eye.fill"
        case .colorBattle: return "bolt.horizontal.fill"
        case .reactionDuel: return "bolt.ring.closed"
        case .dailyChallenge: return "bolt.shield.fill"
        case .quickTap: return "bolt.heart.fill"
        case .sequenceMemory: return "square.grid.2x2.fill"
        case .colorSort: return "paintpalette.fill"
        case .gridReaction: return "bolt.square.fill"
        }
    }
}
