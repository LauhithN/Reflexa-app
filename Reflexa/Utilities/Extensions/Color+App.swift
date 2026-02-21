import SwiftUI

extension Color {
    // MARK: - Surfaces
    static let appBackground = Color(hex: "05020D")
    static let appBackgroundSecondary = Color(hex: "120827")
    static let cardBackground = Color(hex: "161129")
    static let elevatedCard = Color(hex: "231941")
    static let strokeSubtle = Color.white.opacity(0.2)
    static let textPrimary = Color(hex: "F9F7FF")
    static let textSecondary = Color(hex: "B7B5C8")

    // MARK: - Brand Accent
    static let brandPurple = Color(hex: "7B3FF2")
    static let brandPurpleDeep = Color(hex: "5A22C8")
    static let brandYellow = Color(hex: "FFD94D")
    static let brandYellowDeep = Color(hex: "F7B500")
    static let accentPrimary = Color.brandYellow
    static let accentSecondary = Color.brandPurple
    static let accentHot = Color(hex: "FF4F67")
    static let accentSun = Color(hex: "FFB020")
    // MARK: - Player Colors
    static let player1 = Color.brandPurple
    static let player2 = Color(hex: "FF5C69")
    static let player3 = Color(hex: "36D39A")
    static let player4 = Color.brandYellow

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
            colors: [Color.brandPurple, Color.brandYellow],
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
