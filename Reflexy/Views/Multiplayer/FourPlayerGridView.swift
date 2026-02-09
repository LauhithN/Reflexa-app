import SwiftUI

/// 2x2 grid for 4 players.
/// Top-left = P1, Top-right = P2, Bottom-left = P3 (rotated 180), Bottom-right = P4 (rotated 180).
struct FourPlayerGridView<Content: View>: View {
    let content: (Int) -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Top row
            HStack(spacing: 0) {
                content(0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                    .frame(width: 2)
                    .background(Color.gray.opacity(0.3))

                content(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()
                .frame(height: 2)
                .background(Color.gray.opacity(0.3))

            // Bottom row (rotated 180)
            HStack(spacing: 0) {
                content(2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .rotationEffect(.degrees(180))

                Divider()
                    .frame(width: 2)
                    .background(Color.gray.opacity(0.3))

                content(3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .rotationEffect(.degrees(180))
            }
        }
        .ignoresSafeArea()
    }
}
