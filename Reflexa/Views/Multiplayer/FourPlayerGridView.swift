import SwiftUI

struct FourPlayerGridView<Content: View>: View {
    let content: (Int) -> Content

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    content(0)
                        .frame(width: proxy.size.width / 2, height: proxy.size.height / 2)

                    content(1)
                        .frame(width: proxy.size.width / 2, height: proxy.size.height / 2)
                        .rotationEffect(.degrees(90))
                }

                HStack(spacing: 0) {
                    content(2)
                        .frame(width: proxy.size.width / 2, height: proxy.size.height / 2)
                        .rotationEffect(.degrees(270))

                    content(3)
                        .frame(width: proxy.size.width / 2, height: proxy.size.height / 2)
                        .rotationEffect(.degrees(180))
                }
            }
            .overlay {
                CrossDivider()
            }
        }
        .ignoresSafeArea()
    }
}

private struct CrossDivider: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentSecondary.opacity(0.3), Color.accentPrimary.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentSecondary.opacity(0.3), Color.accentPrimary.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 10, height: 10)
                    .shadow(color: Color.accentAmber.opacity(0.5), radius: 10)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
