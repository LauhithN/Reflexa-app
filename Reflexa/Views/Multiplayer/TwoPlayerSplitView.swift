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
                .fill(Color.strokeSubtle)
                .frame(height: 1)
            Circle()
                .fill(Color.textSecondary.opacity(0.5))
                .frame(width: 6, height: 6)
        }
        .frame(height: 12)
        .background(Color.black.opacity(0.25))
        .accessibilityHidden(true)
    }
}
