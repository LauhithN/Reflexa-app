import Foundation

enum PlayerMode: String, CaseIterable, Identifiable, Codable {
    case solo
    case twoPlayer
    case fourPlayer

    var id: String { rawValue }

    var playerCount: Int {
        switch self {
        case .solo: return 1
        case .twoPlayer: return 2
        case .fourPlayer: return 4
        }
    }

    var displayName: String {
        switch self {
        case .solo: return "Solo"
        case .twoPlayer: return "2 Players"
        case .fourPlayer: return "4 Players"
        }
    }

    var iconName: String {
        switch self {
        case .solo: return "person.fill"
        case .twoPlayer: return "person.2.fill"
        case .fourPlayer: return "person.3.fill"
        }
    }
}
