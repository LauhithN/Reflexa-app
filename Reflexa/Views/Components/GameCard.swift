import SwiftUI

/// Minimal game tile used on the home screen.
struct GameCard: View {
    let gameType: GameType
    let action: (() -> Void)?
    @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = 34

    init(gameType: GameType, action: (() -> Void)? = nil) {
        self.gameType = gameType
        self.action = action
    }

    var body: some View {
        let content = tileContent

        if let action {
            Button(action: action) {
                content
            }
            .buttonStyle(CardButtonStyle())
            .accessibilityLabel(accessibilityText)
        } else {
            content
                .accessibilityLabel(accessibilityText)
        }
    }

    private var tileContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.brandYellow.opacity(0.26), Color.brandYellow.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: gameType.iconName)
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(Color.brandYellow)
            }
            .frame(width: 68, height: 68)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.brandYellow.opacity(0.35), lineWidth: 1)
            )

            Spacer(minLength: 0)

            Text(gameType.displayName)
                .font(.playerLabel.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.cardBackground.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var accessibilityText: String {
        "\(gameType.displayName). \(gameType.supportedModes.map { $0.displayName }.joined(separator: ", "))."
    }
}
