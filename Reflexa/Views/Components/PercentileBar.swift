import SwiftUI

/// Visual percentile indicator bar
struct PercentileBar: View {
    let percentile: Int // 0-100

    var body: some View {
        VStack(spacing: 10) {
            Text(Formatters.percentile(percentile))
                .font(.playerLabel.weight(.bold))
                .foregroundStyle(Color.textPrimary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cardBackground.opacity(0.72))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [barColor, barColor.opacity(0.55)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(percentile) / 100)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
            }
            .frame(height: 14)

            HStack {
                Text("Slower")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("Faster")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Percentile: top \(100 - percentile) percent")
    }

    private var barColor: Color {
        switch percentile {
        case 90...: return Color.success
        case 70..<90: return Color.waiting
        case 50..<70: return Color.warning
        default: return Color.error
        }
    }
}
