import SwiftUI

struct MultiplayerArenaLayout<Content: View>: View {
    let playerCount: Int
    let topInset: CGFloat
    let bottomInset: CGFloat
    let outerPadding: CGFloat
    let spacing: CGFloat
    let content: (Int) -> Content

    init(
        playerCount: Int,
        topInset: CGFloat = 96,
        bottomInset: CGFloat = 18,
        outerPadding: CGFloat = 16,
        spacing: CGFloat = 14,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.playerCount = playerCount
        self.topInset = topInset
        self.bottomInset = bottomInset
        self.outerPadding = outerPadding
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        Group {
            if playerCount == 2 {
                TwoPlayerSplitView(
                    topInset: topInset,
                    bottomInset: bottomInset,
                    outerPadding: outerPadding,
                    spacing: spacing,
                    content: content
                )
            } else {
                FourPlayerGridView(
                    topInset: topInset,
                    bottomInset: bottomInset,
                    outerPadding: outerPadding,
                    spacing: spacing,
                    content: content
                )
            }
        }
    }
}

struct TwoPlayerSplitView<Content: View>: View {
    let topInset: CGFloat
    let bottomInset: CGFloat
    let outerPadding: CGFloat
    let spacing: CGFloat
    let content: (Int) -> Content

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom
            let availableHeight = proxy.size.height - safeTop - safeBottom - topInset - bottomInset
            let panelHeight = max(160, (availableHeight - spacing) / 2)

            VStack(spacing: spacing) {
                content(0)
                    .frame(maxWidth: .infinity)
                    .frame(height: panelHeight)

                divider

                content(1)
                    .frame(maxWidth: .infinity)
                    .frame(height: panelHeight)
            }
            .padding(.top, safeTop + topInset)
            .padding(.bottom, safeBottom + bottomInset)
            .padding(.horizontal, outerPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var divider: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentSecondary.opacity(0.2), Color.accentPrimary.opacity(0.26)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 10, height: 10)
                .shadow(color: Color.accentAmber.opacity(0.45), radius: 10)
        }
        .frame(height: 18)
        .background(Color.black.opacity(0.08))
        .accessibilityHidden(true)
    }
}
