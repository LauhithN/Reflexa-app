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
        case .reactionDuel: return "Reaction Duel"
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
        case .colorFlash: return "Tap when screen turns red"
        case .colorBattle: return "First to tap wins"
        case .reactionDuel: return "Fastest reaction wins"
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
        case .reactionDuel: return [.twoPlayer, .fourPlayer]
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

    var iconName: String {
        switch self {
        case .stopwatch: return "stopwatch"
        case .colorFlash: return "bolt.fill"
        case .colorBattle: return "person.2.fill"
        case .reactionDuel: return "flame.fill"
        case .dailyChallenge: return "calendar"
        case .quickTap: return "hand.tap.fill"
        case .soundReflex: return "speaker.wave.2.fill"
        case .vibrationReflex: return "iphone.radiowaves.left.and.right"
        case .gridReaction: return "square.grid.3x3.fill"
        }
    }
}
