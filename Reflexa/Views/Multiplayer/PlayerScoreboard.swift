import SwiftUI

struct PlayerScoreboard: View {
    let players: [PlayerResult]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(players) { player in
                HStack(spacing: 6) {
                    Circle()
                        .fill(player.color)
                        .frame(width: 8, height: 8)

                    Text(initials(for: player.name))
                        .font(.monoSmall)
                        .foregroundStyle(Color.textSecondary)

                    Text("\(Int(player.score.rounded()))")
                        .font(.monoSmall)
                        .monospacedDigit()
                        .foregroundStyle(Color.textPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.24))
                .clipShape(Capsule())
                .animation(Spring.snappy, value: player.score)
            }
        }
        .padding(8)
        .glassCard(cornerRadius: 14)
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
