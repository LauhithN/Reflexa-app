import SwiftUI

struct GhostList: View {
    var items: [String]

    private let opacities: [Double] = [0.75, 0.55, 0.35, 0.2, 0.1]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.prefix(5).enumerated()), id: \.offset) { index, item in
                Text(item)
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)
                    .opacity(opacities[safe: index] ?? 0.1)
                    .offset(y: 12)
                    .animation(Spring.stagger(index), value: items)
                    .onAppear {
                        withAnimation(Spring.stagger(index)) {
                            _ = item
                        }
                    }
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
