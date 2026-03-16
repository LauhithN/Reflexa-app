import SwiftUI

struct PlayerScoreboard: View {
    let players: [PlayerResult]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(players) { player in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(player.color)
                            .frame(width: 10, height: 10)

                        Text(initials(for: player.name))
                            .font(.monoSmall)
                            .foregroundStyle(Color.textPrimary)

                        Text("\(Int(player.score.rounded()))")
                            .font(.monoSmall)
                            .monospacedDigit()
                            .foregroundStyle(Color.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(player.color.opacity(0.16))
                    .overlay(
                        Capsule()
                            .stroke(player.color.opacity(0.42), lineWidth: 1)
                    )
                    .clipShape(Capsule())
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
