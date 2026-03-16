import SwiftUI

struct PlayerScoreboard: View {
    let players: [PlayerResult]
    var activePlayerIndex: Int? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    let isActive = activePlayerIndex == index
                    let pending = player.score.isNaN || player.score < 0

                    HStack(spacing: 8) {
                        Circle()
                            .fill(player.color)
                            .frame(width: 10, height: 10)

                        Text(initials(for: player.name))
                            .font(.monoSmall)
                            .foregroundStyle(Color.textPrimary)

                        Text(pending ? "--" : "\(Int(player.score.rounded()))")
                            .font(.monoSmall)
                            .monospacedDigit()
                            .foregroundStyle(
                                pending
                                ? Color.textTertiary
                                : (isActive ? Color.white : Color.textPrimary)
                            )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isActive ? player.color.opacity(0.26) : player.color.opacity(0.16))
                    .overlay(
                        Capsule()
                            .stroke(isActive ? player.color.opacity(0.8) : player.color.opacity(0.42), lineWidth: isActive ? 1.5 : 1)
                    )
                    .clipShape(Capsule())
                    .shadow(color: isActive ? player.color.opacity(0.28) : .clear, radius: 10)
                    .animation(Spring.snappy, value: player.score)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(10)
        .background(Color.cardBackground.opacity(0.72))
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private func initials(for name: String) -> String {
        let words = name.split(separator: " ").prefix(2)
        let letters = words.compactMap { $0.first }.map(String.init)
        if letters.isEmpty {
            return "P"
        }
        return letters.joined()
    }
}
