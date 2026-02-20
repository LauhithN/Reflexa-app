import SwiftUI

/// Card for displaying a game option on the home screen
struct GameCard: View {
    let gameType: GameType
    let action: (() -> Void)?
    @ScaledMetric(relativeTo: .title3) private var iconSize: CGFloat = 48
    @ScaledMetric(relativeTo: .caption) private var chipHorizontalPadding: CGFloat = 8
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
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
                        .font(.system(size: iconSize * 0.45, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: iconSize, height: iconSize)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.textSecondary)
                    .padding(8)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Circle())
            }

            Text(gameType.displayName)
                .font(.playerLabel.weight(.bold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(gameType.description)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                .fixedSize(horizontal: false, vertical: true)

            modeChips
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 190 : 172, alignment: .topLeading)
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

    private var modeChips: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 6) {
                ForEach(gameType.supportedModes) { mode in
                    modeChip(mode.displayName)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(gameType.supportedModes) { mode in
                    modeChip(mode.displayName)
                }
            }
        }
    }

    private func modeChip(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Color.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, chipHorizontalPadding)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.06))
            .clipShape(Capsule())
    }

    private var cardTint: Color {
        Color.accentPrimary
    }

    private var accessibilityText: String {
        "\(gameType.displayName). \(gameType.description). Modes: \(gameType.supportedModes.map(\.displayName).joined(separator: ", "))."
    }
}
