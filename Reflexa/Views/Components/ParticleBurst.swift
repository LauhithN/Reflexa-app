import SwiftUI

struct ParticleBurst: View {
    @Binding var trigger: Bool
    var particleCount: Int = 25

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [Particle] = []
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                if particle.rounded {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .offset(
                            x: animate ? cos(particle.angle) * particle.distance : 0,
                            y: animate ? sin(particle.angle) * particle.distance : 0
                        )
                        .opacity(animate ? 0 : 1)
                } else {
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .offset(
                            x: animate ? cos(particle.angle) * particle.distance : 0,
                            y: animate ? sin(particle.angle) * particle.distance : 0
                        )
                        .opacity(animate ? 0 : 1)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { newValue in
            guard newValue else { return }
            fire()
        }
    }

    private func fire() {
        guard !reduceMotion else {
            trigger = false
            return
        }

        particles = (0..<particleCount).map { _ in
            Particle(
                angle: Double.random(in: 0...(Double.pi * 2)),
                distance: Double.random(in: 90...160),
                size: CGFloat.random(in: 4...8),
                color: [.accentPrimary, .accentSecondary, .accentAmber].randomElement() ?? .accentPrimary,
                rounded: Bool.random()
            )
        }

        animate = false
        withAnimation(Spring.easeOut(duration: 0.85)) {
            animate = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            particles = []
            animate = false
            trigger = false
        }
    }
}

private struct Particle: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: Double
    let size: CGFloat
    let color: Color
    let rounded: Bool
}
