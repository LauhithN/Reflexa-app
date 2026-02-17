import SwiftUI

/// Vertical split for 2 players.
/// Player 1 = top half. Player 2 = bottom half, rotated 180 degrees.
struct TwoPlayerSplitView<Content: View>: View {
    let content: (Int) -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Player 1 (top)
            content(0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .frame(height: 2)
                .overlay(Color.strokeSubtle)

            // Player 2 (bottom, rotated 180)
            content(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .rotationEffect(.degrees(180))
        }
        .ignoresSafeArea()
    }
}
