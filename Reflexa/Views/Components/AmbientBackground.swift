import SwiftUI

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

            orb(color: .accentPrimary.opacity(0.32), size: 320, start: .init(x: -180, y: -240), end: .init(x: -120, y: -180), duration: 16)
            orb(color: .accentAmber.opacity(0.18), size: 240, start: .init(x: 160, y: -220), end: .init(x: 120, y: -260), duration: 13)
            orb(color: .accentHot.opacity(0.14), size: 280, start: .init(x: -40, y: 220), end: .init(x: 20, y: 280), duration: 21)
            orb(color: .accentSecondary.opacity(0.20), size: 200, start: .init(x: 170, y: 260), end: .init(x: 120, y: 220), duration: 18)

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.45)],
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

    private func orb(color: Color, size: CGFloat, start: CGPoint, end: CGPoint, duration: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, Color.clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 4)
            .offset(
                x: reduceMotion ? start.x : (animate ? end.x : start.x),
                y: reduceMotion ? start.y : (animate ? end.y : start.y)
            )
            .animation(
                reduceMotion ? nil : Spring.ambient(duration: duration).repeatForever(autoreverses: true),
                value: animate
            )
    }
}
