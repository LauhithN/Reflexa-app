import SwiftUI

/// Card for displaying a game option on the home screen
struct GameCard: View {
    let gameType: GameType
    let action: (() -> Void)?

    init(gameType: GameType, action: (() -> Void)? = nil) {
        self.gameType = gameType
        self.action = action
    }

    var body: some View {
        let content = cardContent

        if let action {
            Button(action: action) {
                content
            }
            .buttonStyle(CardButtonStyle())
            .accessibleTapTarget()
            .accessibilityLabel(accessibilityText)
        } else {
            content
                .accessibleTapTarget()
                .accessibilityLabel(accessibilityText)
        }
    }

    private var cardContent: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [cardTint.opacity(0.95), cardTint.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: gameType.iconName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 8) {
                Text(gameType.displayName)
                    .font(.playerLabel.weight(.bold))
                    .foregroundStyle(Color.textPrimary)

                Text(gameType.description)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: 6) {
                    ForEach(gameType.supportedModes) { mode in
                        modeChip(mode.displayName)
                    }
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.textSecondary)
                .padding(8)
                .background(Color.white.opacity(0.05))
                .clipShape(Circle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.elevatedCard.opacity(0.95), Color.cardBackground.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func modeChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.06))
            .clipShape(Capsule())
    }

    private var cardTint: Color {
        switch gameType {
        case .dailyChallenge:
            return Color.accentSecondary
        default:
            return Color.accentPrimary
        }
    }

    private var accessibilityText: String {
        "\(gameType.displayName). \(gameType.description)."
    }
}
