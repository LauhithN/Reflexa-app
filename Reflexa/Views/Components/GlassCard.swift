import SwiftUI

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.elevatedCard.opacity(0.96), Color.cardBackground.opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.16), Color.clear, Color.accentSecondary.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.28),
                                        Color.accentPrimary.opacity(0.22),
                                        Color.accentSecondary.opacity(0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.15
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.black.opacity(0.24), lineWidth: 1)
                            .blur(radius: 10)
                            .offset(y: 8)
                            .mask(
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.black, Color.clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                    )
                    .shadow(color: Color.accentPrimary.opacity(0.16), radius: 28, y: 14)
            )
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

struct BrandMark: View {
    var size: CGFloat = 72
    var showSparkles: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.96)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.accentPrimary.opacity(0.28), radius: size * 0.18, y: size * 0.08)

            Text("R")
                .font(.system(size: size * 0.54, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentSecondary, Color.accentPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(-6))
                .offset(y: size * 0.02)

            if showSparkles {
                Circle()
                    .fill(Color.accentAmber)
                    .frame(width: size * 0.11, height: size * 0.11)
                    .offset(x: size * 0.22, y: -size * 0.22)

                Circle()
                    .fill(Color.accentHot.opacity(0.9))
                    .frame(width: size * 0.06, height: size * 0.06)
                    .offset(x: -size * 0.24, y: size * 0.2)
            }
        }
        .frame(width: size, height: size)
    }
}
