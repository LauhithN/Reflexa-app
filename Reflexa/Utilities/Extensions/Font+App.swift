import SwiftUI

extension Font {
    static let heroTitle = Font.system(size: 40, weight: .black, design: .rounded).leading(.tight)
    static let sectionTitle = Font.system(size: 24, weight: .bold, design: .rounded)
    static let countdownNumber = Font.system(size: 120, weight: .bold, design: .rounded)
    static let gameTitle = Font.system(size: 30, weight: .bold, design: .rounded)
    static let playerLabel = Font.system(.body, design: .rounded, weight: .semibold)
    static let resultTitle = Font.system(.title, design: .rounded, weight: .bold)
    static let resultScore = Font.system(size: 50, weight: .bold, design: .rounded)
    static let bodyLarge = Font.system(.title3, design: .rounded, weight: .medium)
    static let caption = Font.system(.footnote, design: .rounded, weight: .semibold)
}
