import SwiftUI

/// 2x2 grid for 4 players.
/// Top-left = P1, Top-right = P2, Bottom-left = P3 (rotated 180), Bottom-right = P4 (rotated 180).
struct FourPlayerGridView<Content: View>: View {
    let content: (Int) -> Content
    private let deadZoneSize: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            // Top row
            HStack(spacing: 0) {
                content(0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                verticalDeadZone

                content(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            horizontalDeadZone

            // Bottom row (rotated 180)
            HStack(spacing: 0) {
                content(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .rotationEffect(.degrees(180))

                verticalDeadZone

                content(3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .rotationEffect(.degrees(180))
            }
        }
        .ignoresSafeArea()
    }

    private var horizontalDeadZone: some View {
        Rectangle()
            .fill(Color.black.opacity(0.22))
            .frame(height: deadZoneSize)
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

    private var verticalDeadZone: some View {
        Rectangle()
            .fill(Color.black.opacity(0.22))
            .frame(width: deadZoneSize)
            .overlay(
                Rectangle()
                    .fill(Color.strokeSubtle)
                    .frame(width: 1),
                alignment: .leading
            )
            .overlay(
                Rectangle()
                    .fill(Color.strokeSubtle)
                    .frame(width: 1),
                alignment: .trailing
            )
            .contentShape(Rectangle())
            .onTapGesture { }
            .accessibilityHidden(true)
    }
}
