import SwiftUI

struct GameCard: View {
    let gameType: GameType
    let action: (() -> Void)?

    init(gameType: GameType, action: (() -> Void)? = nil) {
        self.gameType = gameType
        self.action = action
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(CardButtonStyle())
            } else {
                cardContent
            }
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.accentPrimary.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: gameType.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(gameType.displayName)
                        .font(.sectionTitle)
                        .foregroundStyle(Color.textPrimary)
                    Text(gameType.description)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                ForEach(gameType.supportedModes) { mode in
                    Text(mode == .solo ? "Solo" : mode == .twoPlayer ? "2P" : "4P")
                        .font(.monoSmall)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)

                Text(gameType.difficulty.displayName)
                    .font(.monoSmall)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.cardBackground)
                    .overlay(
                        Capsule().stroke(Color.strokeSubtle, lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(alignment: .leading) {
            Rectangle()
                .fill(Color.accentPrimary)
                .frame(width: 3)
        }
        .glassCard(cornerRadius: 18)
    }

    private var accessibilityLabel: String {
        let modes = gameType.supportedModes.map(\.displayName).joined(separator: ", ")
        return "\(gameType.displayName). \(gameType.description). Modes: \(modes)."
    }
}
