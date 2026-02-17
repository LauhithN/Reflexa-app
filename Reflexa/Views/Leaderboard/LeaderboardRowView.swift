import SwiftUI

struct LeaderboardRowView: View {
    let rank: Int
    let score: String
    let date: Date

    private var rankLabel: String {
        switch rank {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(rank)th"
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "FFD700")
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(rankColor.opacity(rank <= 3 ? 0.22 : 0.12))
                    .frame(width: 34, height: 34)

                Text(rankLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(rankColor)
            }

            Text(score)
                .font(.playerLabel)
                .monospacedDigit()
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Text(shortDate)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
        )
    }

    private var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
