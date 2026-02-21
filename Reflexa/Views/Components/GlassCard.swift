import SwiftUI

struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.cardBackground.opacity(0.4))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.strokeSubtle, lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            .blur(radius: 4)
                            .offset(y: 1)
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
