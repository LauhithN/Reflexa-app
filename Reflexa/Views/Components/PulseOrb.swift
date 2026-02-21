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
                .fill(color)
                .frame(width: size * 0.52, height: size * 0.52)

            Circle()
                .fill(color.opacity(0.12))
                .frame(width: size, height: size)
                .scaleEffect(animate ? pulseScale : 1)
                .opacity(animate ? 0.2 : 0.6)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(Spring.ambient(duration: pulseDuration).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
