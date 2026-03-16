import SwiftUI

struct PulseOrb: View {
    var color: Color = .accentPrimary
    var size: CGFloat = 120
    var pulseScale: CGFloat = 1.25
    var pulseDuration: Double = 1.8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.9), color, color.opacity(0.65)],
                        center: .center,
                        startRadius: 1,
                        endRadius: size * 0.24
                    )
                )
                .frame(width: size * 0.5, height: size * 0.5)

            Circle()
                .stroke(color.opacity(0.55), lineWidth: 2)
                .frame(width: size * 0.68, height: size * 0.68)

            Circle()
                .fill(color.opacity(0.12))
                .frame(width: size, height: size)
                .scaleEffect(animate ? pulseScale : 1)
                .opacity(animate ? 0.2 : 0.6)
        }
        .shadow(color: color.opacity(0.35), radius: size * 0.16)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(Spring.ambient(duration: pulseDuration).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
