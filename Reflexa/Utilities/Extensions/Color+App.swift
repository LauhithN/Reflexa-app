import SwiftUI

extension Color {
    // MARK: - Surfaces
    static let appBackground = Color(hex: "060A14")
    static let appBackgroundSecondary = Color(hex: "0B1326")
    static let cardBackground = Color(hex: "121C31")
    static let elevatedCard = Color(hex: "192744")
    static let strokeSubtle = Color.white.opacity(0.25)
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "C8D3EB")

    // MARK: - Brand Accent
    static let accentPrimary = Color(hex: "5B8CFF")
    static let accentSecondary = Color(hex: "2DD4BF")
    static let accentHot = Color(hex: "FB7185")
    static let accentSun = Color(hex: "F59E0B")
    // MARK: - Player Colors
    static let player1 = Color(hex: "5B8CFF")
    static let player2 = Color(hex: "F87171")
    static let player3 = Color(hex: "34D399")
    static let player4 = Color(hex: "F59E0B")

    // MARK: - States
    static let success = Color(hex: "34D399")
    static let error = Color(hex: "FB7185")
    static let warning = Color(hex: "FBBF24")
    static let waiting = Color.accentPrimary
    // MARK: - Gradients
    static var appGradient: LinearGradient {
        LinearGradient(
            colors: [Color.appBackgroundSecondary, Color.appBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentPrimary, Color.accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

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
