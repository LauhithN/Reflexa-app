import SwiftUI

/// Shared primary/secondary action row used on result and retry screens.
struct GameActionButtons: View {
    let primaryTitle: String
    let secondaryTitle: String
    let primaryTint: Color
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    init(
        primaryTitle: String = "Play Again",
        secondaryTitle: String = "Menu",
        primaryTint: Color = .accentPrimary,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void
    ) {
        self.primaryTitle = primaryTitle
        self.secondaryTitle = secondaryTitle
        self.primaryTint = primaryTint
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(primaryTitle, action: onPrimary)
                .buttonStyle(PrimaryCTAButtonStyle(tint: primaryTint))
                .accessibleTapTarget()

            Button(secondaryTitle, action: onSecondary)
                .buttonStyle(SecondaryCTAButtonStyle())
                .accessibleTapTarget()
        }
    }
}
