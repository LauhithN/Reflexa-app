import SwiftUI

struct TwoPlayerSplitView<Content: View>: View {
    let content: (Int) -> Content

    var body: some View {
        VStack(spacing: 0) {
            content(0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            divider

            content(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }

    private var divider: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentSecondary.opacity(0.32), Color.accentPrimary.opacity(0.32)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 8, height: 8)
                .shadow(color: Color.accentAmber.opacity(0.45), radius: 8)
        }
        .frame(height: 12)
        .background(Color.black.opacity(0.16))
        .accessibilityHidden(true)
    }
}
