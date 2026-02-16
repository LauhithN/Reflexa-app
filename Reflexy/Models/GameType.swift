import Foundation

enum GameType: String, CaseIterable, Identifiable, Codable {
    // Free games
    case stopwatch
    case colorFlash
    case colorBattle
    case reactionDuel
    case dailyChallenge

    // Premium games
    case quickTap
    case soundReflex
    case vibrationReflex
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
        case .soundReflex: return "Sound Reflex"
        case .vibrationReflex: return "Vibration Reflex"
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
        case .soundReflex: return "React to the beep"
        case .vibrationReflex: return "React to the buzz"
        case .gridReaction: return "Tap the lit square"
        }
    }

    var isPremium: Bool {
        switch self {
        case .quickTap, .soundReflex, .vibrationReflex, .gridReaction:
            return true
        default:
            return false
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
        case .soundReflex: return [.solo, .twoPlayer, .fourPlayer]
        case .vibrationReflex: return [.solo, .twoPlayer, .fourPlayer]
        case .gridReaction: return [.solo]
        }
    }

    /// Whether lower score is better for this game type
    var lowerIsBetter: Bool {
        switch self {
        case .quickTap: return false
        default: return true
        }
    }

    /// Format a score for display in leaderboards and results
    func formatScore(_ score: Double) -> String {
        switch self {
        case .stopwatch:
            return Formatters.stopwatchValue(score)
        case .quickTap:
            return Formatters.tapCount(Int(score))
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
        case .soundReflex: return "ear.fill"
        case .vibrationReflex: return "hand.point.up.fill"
        case .gridReaction: return "bolt.square.fill"
        }
    }
}
