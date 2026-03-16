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
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(accentPair.0.opacity(0.24))
                .frame(width: 110, height: 110)
                .blur(radius: 8)
                .offset(x: 34, y: -26)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accentPair.0, accentPair.1],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .overlay(
                            Image(systemName: gameType.iconName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.white)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(gameType.displayName)
                            .font(.sectionTitle)
                            .foregroundStyle(Color.textPrimary)

                        Text(gameType.description)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                }

                HStack(spacing: 6) {
                    ForEach(gameType.supportedModes) { mode in
                        Text(mode == .solo ? "Solo" : mode == .twoPlayer ? "2P" : "4P")
                            .font(.monoSmall)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.09))
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: 0)

                    Text(gameType.difficulty.displayName.uppercased())
                        .font(.monoSmall)
                        .foregroundStyle(accentPair.0)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accentPair.0.opacity(0.14))
                        .overlay(
                            Capsule().stroke(accentPair.0.opacity(0.4), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 18)
    }

    private var accessibilityLabel: String {
        let modes = gameType.supportedModes.map(\.displayName).joined(separator: ", ")
        return "\(gameType.displayName). \(gameType.description). Modes: \(modes)."
    }

    private var accentPair: (Color, Color) {
        switch gameType {
        case .stopwatch:
            return (.accentAmber, .accentPrimary)
        case .colorFlash:
            return (.accentSecondary, .accentBlue)
        case .quickTap:
            return (.accentSecondary, .accentPrimary)
        case .sequenceMemory:
            return (.accentLilac, .accentHot)
        case .colorSort:
            return (.accentPrimary, .accentAmber)
        case .gridReaction:
            return (.accentBlue, .accentSecondary)
        case .reactionDuel:
            return (.accentAmber, .accentHot)
        case .colorBattle:
            return (.accentPrimary, .accentSecondary)
        }
    }
}
