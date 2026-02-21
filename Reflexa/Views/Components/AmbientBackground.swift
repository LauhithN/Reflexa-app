import SwiftUI

/// Reusable animated backdrop that gives screens a modern, layered feel.
struct AmbientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appBackgroundSecondary, Color.appBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.brandPurple.opacity(0.4), Color.clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 360
            )

            orb(
                colors: [Color.brandYellow.opacity(0.22), Color.clear],
                size: 380,
                x: animate ? -140 : -200,
                y: animate ? -230 : -140,
                duration: 14
            )

            orb(
                colors: [Color.brandYellow.opacity(0.36), Color.clear],
                size: 320,
                x: animate ? 170 : 120,
                y: animate ? 280 : 220,
                duration: 12
            )

            RoundedRectangle(cornerRadius: 180, style: .continuous)
                .fill(Color.brandYellow.opacity(0.12))
                .frame(width: 300, height: 120)
                .rotationEffect(.degrees(-16))
                .blur(radius: 45)
                .offset(x: animate ? 30 : -40, y: animate ? -120 : -160)
                .animation(
                    reduceMotion
                        ? nil
                        : .easeInOut(duration: 11).repeatForever(autoreverses: true),
                    value: animate
                )

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.36)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            animate = true
        }
    }

    private func orb(
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
