import SwiftUI

/// Reusable animated backdrop that gives screens a modern, layered feel.
struct AmbientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.appBackground

            LinearGradient(
                colors: [Color.appBackgroundSecondary.opacity(0.95), Color.appBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            glow(
                colors: [Color.accentPrimary.opacity(0.55), Color.clear],
                size: 360,
                x: animate ? -120 : -180,
                y: animate ? -240 : -150,
                duration: 13
            )

            glow(
                colors: [Color.accentSecondary.opacity(0.5), Color.clear],
                size: 300,
                x: animate ? 150 : 110,
                y: animate ? 300 : 230,
                duration: 11
            )

            glow(
                colors: [Color.accentHot.opacity(0.35), Color.clear],
                size: 260,
                x: animate ? 170 : 110,
                y: animate ? -190 : -120,
                duration: 14
            )
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            animate = true
        }
    }

    private func glow(
        colors: [Color],
        size: CGFloat,
        x: CGFloat,
        y: CGFloat,
        duration: Double
    ) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: colors,
                    center: .center,
                    startRadius: 10,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .offset(x: x, y: y)
            .blur(radius: 6)
            .animation(
                reduceMotion
                    ? nil
                    : .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: animate
            )
    }
}
