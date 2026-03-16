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

enum GamePlayStyle: String, CaseIterable, Identifiable, Codable {
    case simultaneous
    case turnBased

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simultaneous:
            return "Simultaneous"
        case .turnBased:
            return "Turn-Based"
        }
    }

    var iconName: String {
        switch self {
        case .simultaneous:
            return "square.split.2x2.fill"
        case .turnBased:
            return "person.crop.rectangle.stack.fill"
        }
    }

    var summary: String {
        switch self {
        case .simultaneous:
            return "Everyone plays on their own zone at the same time."
        case .turnBased:
            return "One player is active at a time with a pass-device handoff."
        }
    }

    var setupLabel: String {
        switch self {
        case .simultaneous:
            return "Shared-device split layout"
        case .turnBased:
            return "Sequential turns with handoff"
        }
    }
}
