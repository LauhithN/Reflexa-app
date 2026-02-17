import SwiftUI

/// Card for displaying a game option on the home screen
struct GameCard: View {
    let gameType: GameType
    let isLocked: Bool
    let action: (() -> Void)?

    init(gameType: GameType, isLocked: Bool, action: (() -> Void)? = nil) {
        self.gameType = gameType
        self.isLocked = isLocked
        self.action = action
    }

    var body: some View {
        let content = cardContent

        if let action {
            Button(action: action) {
                content
            }
            .accessibleTapTarget()
            .accessibilityLabel(accessibilityText)
        } else {
            content
                .accessibleTapTarget()
                .accessibilityLabel(accessibilityText)
        }
    }

    private var cardContent: some View {
        HStack(spacing: 16) {
            Image(systemName: gameType.iconName)
                .font(.system(size: 24))
                .foregroundStyle(isLocked ? .gray : Color(hex: "FBBF24"))
                .frame(width: 44, height: 44)
                .background(isLocked ? Color.cardBackground : Color(hex: "A855F7"))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(gameType.displayName)
                        .font(.playerLabel)
                        .foregroundStyle(.white)

                    if isLocked {
                        UnlockBadge()
                    }
                }

                Text(gameType.description)
                    .font(.caption)
                    .foregroundStyle(.gray)

                HStack(spacing: 8) {
                    ForEach(gameType.supportedModes) { mode in
                        Text(mode.displayName)
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.cardBackground)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    private var accessibilityText: String {
        "\(gameType.displayName). \(gameType.description). \(isLocked ? "Premium, locked" : "")"
    }
}
