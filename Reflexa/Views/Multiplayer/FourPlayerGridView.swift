import SwiftUI

struct FourPlayerGridView<Content: View>: View {
    let topInset: CGFloat
    let bottomInset: CGFloat
    let outerPadding: CGFloat
    let spacing: CGFloat
    let content: (Int) -> Content

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom
            let totalHeight = proxy.size.height - safeTop - safeBottom - topInset - bottomInset
            let panelHeight = max(132, (totalHeight - spacing) / 2)
            let panelWidth = max(132, (proxy.size.width - (outerPadding * 2) - spacing) / 2)

            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    content(0)
                        .frame(width: panelWidth, height: panelHeight)

                    content(1)
                        .frame(width: panelWidth, height: panelHeight)
                }

                HStack(spacing: spacing) {
                    content(2)
                        .frame(width: panelWidth, height: panelHeight)

                    content(3)
                        .frame(width: panelWidth, height: panelHeight)
                }
            }
            .padding(.top, safeTop + topInset)
            .padding(.bottom, safeBottom + bottomInset)
            .padding(.horizontal, outerPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay {
                CrossDivider(
                    topInset: safeTop + topInset,
                    sideInset: outerPadding,
                    bottomInset: safeBottom + bottomInset,
                    spacing: spacing
                )
            }
        }
    }
}

private struct CrossDivider: View {
    let topInset: CGFloat
    let sideInset: CGFloat
    let bottomInset: CGFloat
    let spacing: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let safeHeight = proxy.size.height - topInset - bottomInset
            let centerY = topInset + (safeHeight / 2)
            let centerX = proxy.size.width / 2

            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentSecondary.opacity(0.16), Color.accentPrimary.opacity(0.22)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: max(0, safeHeight - spacing))
                    .position(x: centerX, y: centerY)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentSecondary.opacity(0.16), Color.accentPrimary.opacity(0.22)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, proxy.size.width - (sideInset * 2) - spacing), height: 2)
                    .position(x: centerX, y: centerY)

                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 12, height: 12)
                    .shadow(color: Color.accentAmber.opacity(0.5), radius: 12)
                    .position(x: centerX, y: centerY)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct MultiplayerPlayerPanel<HeaderTrailing: View, Content: View>: View {
    let name: String
    let accentColor: Color
    var subtitle: String?
    var compact: Bool = false
    var inactive: Bool = false
    let headerTrailing: HeaderTrailing
    let content: Content

    init(
        name: String,
        accentColor: Color,
        subtitle: String? = nil,
        compact: Bool = false,
        inactive: Bool = false,
        @ViewBuilder headerTrailing: () -> HeaderTrailing,
        @ViewBuilder content: () -> Content
    ) {
        self.name = name
        self.accentColor = accentColor
        self.subtitle = subtitle
        self.compact = compact
        self.inactive = inactive
        self.headerTrailing = headerTrailing()
        self.content = content()
    }

    private var cornerRadius: CGFloat {
        compact ? 22 : 28
    }

    private var paddingValue: CGFloat {
        compact ? 12 : 16
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accentColor)
                            .frame(width: compact ? 8 : 10, height: compact ? 8 : 10)

                        Text(name)
                            .font(compact ? .bodyLarge : .sectionTitle)
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(.monoSmall)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 12)

                headerTrailing
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(paddingValue)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(background)
        .overlay(border)
        .overlay {
            if inactive {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.22))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: accentColor.opacity(compact ? 0.14 : 0.2), radius: compact ? 12 : 18, y: compact ? 8 : 12)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        accentColor.opacity(inactive ? 0.08 : 0.18),
                        Color.cardBackground.opacity(0.94),
                        Color.inkPanel.opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.clear, accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        accentColor.opacity(inactive ? 0.28 : 0.8),
                        Color.white.opacity(0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: inactive ? 1 : 1.8
            )
    }
}
