import SwiftUI

extension Color {
    // MARK: - Surfaces
    static let appBackground = Color(hex: "#0A0A0F")
    static let appBackgroundSecondary = Color(hex: "#0F0F18")
    static let cardBackground = Color(hex: "#14141C")
    static let elevatedCard = Color(hex: "#1C1C28")
    static let strokeSubtle = Color.white.opacity(0.07)

    // MARK: - Accent Palette
    static let accentPrimary = Color(hex: "#7B68EE")
    static let accentSecondary = Color(hex: "#5EE7A0")
    static let accentHot = Color(hex: "#FF6B6B")
    static let accentAmber = Color(hex: "#FFD166")

    // MARK: - Players
    static let player1Color = Color(hex: "#4FC3F7")
    static let player2Color = Color(hex: "#FF8A65")
    static let player3Color = Color(hex: "#CE93D8")
    static let player4Color = Color(hex: "#A5D6A7")

    // MARK: - Typography
    static let textPrimary = Color(hex: "#F0F0F8")
    static let textSecondary = Color(hex: "#888899")
    static let textTertiary = Color(hex: "#555566")

    // MARK: - Semantic
    static let success = Color(hex: "#5EE7A0")
    static let warning = Color(hex: "#FFD166")
    static let destructive = Color(hex: "#FF6B6B")

    // Compatibility aliases
    static let error = destructive
    static let waiting = accentPrimary
    static let brandPurple = accentPrimary
    static let brandPurpleDeep = accentPrimary.opacity(0.82)
    static let brandYellow = accentAmber
    static let brandYellowDeep = accentAmber.opacity(0.8)
    static let accentSun = accentAmber
    static let player1 = player1Color
    static let player2 = player2Color
    static let player3 = player3Color
    static let player4 = player4Color

    static func playerColor(for index: Int) -> Color {
        switch index {
        case 0: return .player1Color
        case 1: return .player2Color
        case 2: return .player3Color
        case 3: return .player4Color
        default: return .player1Color
        }
    }

    init(hex: String) {
        let hexValue = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexValue).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hexValue.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xff, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
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
