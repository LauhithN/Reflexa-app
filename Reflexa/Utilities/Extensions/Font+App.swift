import SwiftUI
import UIKit

extension Font {
    static let heroTitle = rounded(size: 42, weight: .black, relativeTo: .largeTitle)
    static let resultTitle = rounded(size: 30, weight: .black, relativeTo: .title2)
    static let sectionTitle = rounded(size: 18, weight: .bold, relativeTo: .headline)
    static let playerLabel = rounded(size: 15, weight: .semibold, relativeTo: .subheadline)
    static let bodyLarge = rounded(size: 16, weight: .medium, relativeTo: .body)
    static let heroCaption = rounded(size: 19, weight: .heavy, relativeTo: .title3)

    static let monoTime = jetBrains(size: 48, relativeTo: .largeTitle)
    static let monoLarge = jetBrains(size: 72, relativeTo: .largeTitle)
    static let monoSmall = jetBrains(size: 13, relativeTo: .caption)

    static let countdownNumber = monoLarge.weight(.black)
    static let gameTitle = resultTitle
    static let resultScore = monoLarge
    static let caption = plusJakarta(size: 12, weight: .semibold, relativeTo: .caption)

    private static func rounded(size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle) -> Font {
        if UIFont(name: "PlusJakartaSans-Variable", size: size) != nil {
            return .custom("PlusJakartaSans-Variable", size: size, relativeTo: relativeTo).weight(weight)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }

    private static func plusJakarta(size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle) -> Font {
        if UIFont(name: "PlusJakartaSans-Variable", size: size) != nil {
            return .custom("PlusJakartaSans-Variable", size: size, relativeTo: relativeTo).weight(weight)
        }
        if UIFont(name: "Inter", size: size) != nil {
            return .custom("Inter", size: size, relativeTo: relativeTo).weight(weight)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }

    private static func jetBrains(size: CGFloat, relativeTo: Font.TextStyle) -> Font {
        if UIFont(name: "JetBrainsMono-Regular", size: size) != nil {
            return .custom("JetBrainsMono-Regular", size: size, relativeTo: relativeTo)
        }
        return .system(size: size, weight: .regular, design: .monospaced)
    }
}
