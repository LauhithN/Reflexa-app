import SwiftUI

/// Vertical split for 2 players.
/// Player 1 = top half. Player 2 = bottom half, rotated 180 degrees.
struct TwoPlayerSplitView<Content: View>: View {
    let content: (Int) -> Content
    private let deadZoneHeight: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            // Player 1 (top)
            content(0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            deadZone

            // Player 2 (bottom, rotated 180)
            content(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .rotationEffect(.degrees(180))
        }
        .ignoresSafeArea()
    }

    private var deadZone: some View {
        Rectangle()
            .fill(Color.black.opacity(0.22))
            .frame(height: deadZoneHeight)
            .overlay(
                Rectangle()
                    .fill(Color.strokeSubtle)
                    .frame(height: 1),
                alignment: .top
            )
            .overlay(
                Rectangle()
                    .fill(Color.strokeSubtle)
                    .frame(height: 1),
                alignment: .bottom
            )
            .contentShape(Rectangle())
            .onTapGesture { }
            .accessibilityHidden(true)
    }
}
