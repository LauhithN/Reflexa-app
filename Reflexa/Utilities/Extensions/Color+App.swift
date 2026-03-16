import SwiftUI

extension Color {
    // MARK: - Surfaces
    static let appBackground = Color(hex: "#120426")
    static let appBackgroundSecondary = Color(hex: "#261052")
    static let cardBackground = Color(hex: "#1B0F3E")
    static let elevatedCard = Color(hex: "#28175C")
    static let inkPanel = Color(hex: "#130A2C")
    static let strokeSubtle = Color.white.opacity(0.12)

    // MARK: - Accent Palette
    static let accentPrimary = Color(hex: "#FF72B6")
    static let accentSecondary = Color(hex: "#57F4D0")
    static let accentHot = Color(hex: "#6978FF")
    static let accentAmber = Color(hex: "#FFD95A")
    static let accentBlue = Color(hex: "#76D9FF")
    static let accentLilac = Color(hex: "#C58CFF")

    // MARK: - Players
    static let player1Color = Color(hex: "#69E7FF")
    static let player2Color = Color(hex: "#FFD44A")
    static let player3Color = Color(hex: "#C675FF")
    static let player4Color = Color(hex: "#62F3A2")

    // MARK: - Typography
    static let textPrimary = Color(hex: "#FFF7FF")
    static let textSecondary = Color(hex: "#D3C7F4")
    static let textTertiary = Color(hex: "#8C7DAA")

    // MARK: - Semantic
    static let success = accentSecondary
    static let warning = accentAmber
    static let destructive = Color(hex: "#FF7A91")

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
