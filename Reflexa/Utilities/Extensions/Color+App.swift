import SwiftUI

extension Color {
    // MARK: - Backgrounds
    static let appBackground = Color(hex: "1C1C1E")
    static let cardBackground = Color(hex: "2C2C2E")

    // MARK: - Player Colors
    static let player1 = Color(hex: "3B82F6")
    static let player2 = Color(hex: "EF4444")
    static let player3 = Color(hex: "22C55E")
    static let player4 = Color(hex: "F97316")

    // MARK: - States
    static let success = Color(hex: "22C55E")
    static let error = Color(hex: "F87171")
    static let warning = Color(hex: "FBBF24")
    static let waiting = Color(hex: "3B82F6")
    static let unlockBadge = Color(hex: "F97316")

    static func playerColor(for index: Int) -> Color {
        switch index {
        case 0: return .player1
        case 1: return .player2
        case 2: return .player3
        case 3: return .player4
        default: return .player1
        }
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
