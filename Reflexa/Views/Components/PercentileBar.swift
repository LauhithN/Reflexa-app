import SwiftUI

/// Visual percentile indicator bar
struct PercentileBar: View {
    let percentile: Int // 0-100

    var body: some View {
        VStack(spacing: 8) {
            Text(Formatters.percentile(percentile))
                .font(.playerLabel)
                .foregroundStyle(.white)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.cardBackground)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(percentile) / 100)
                }
            }
            .frame(height: 12)

            HStack {
                Text("Slower")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Spacer()
                Text("Faster")
                    .font(.caption)
                    .foregroundStyle(.gray)
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
