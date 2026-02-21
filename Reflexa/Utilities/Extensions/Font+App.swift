import SwiftUI
import UIKit

extension Font {
    static let heroTitle = plusJakarta(size: 34, weight: .black, relativeTo: .largeTitle)
    static let resultTitle = plusJakarta(size: 28, weight: .bold, relativeTo: .title2)
    static let sectionTitle = plusJakarta(size: 17, weight: .semibold, relativeTo: .headline)
    static let playerLabel = plusJakarta(size: 15, weight: .medium, relativeTo: .subheadline)
    static let bodyLarge = plusJakarta(size: 15, weight: .regular, relativeTo: .body)

    static let monoTime = jetBrains(size: 48, relativeTo: .largeTitle)
    static let monoLarge = jetBrains(size: 72, relativeTo: .largeTitle)
    static let monoSmall = jetBrains(size: 13, relativeTo: .caption)

    static let countdownNumber = monoLarge.weight(.black)
    static let gameTitle = resultTitle
    static let resultScore = monoLarge
    static let caption = plusJakarta(size: 12, weight: .semibold, relativeTo: .caption)

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
