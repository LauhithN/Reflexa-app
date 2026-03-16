import SwiftUI

struct AmbientBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appBackgroundSecondary, Color.appBackground, Color.inkPanel],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            orb(color: .accentPrimary.opacity(0.42), size: 360, start: .init(x: -180, y: -260), end: .init(x: -110, y: -190), duration: 16)
            orb(color: .accentSecondary.opacity(0.28), size: 240, start: .init(x: 170, y: -180), end: .init(x: 120, y: -240), duration: 14)
            orb(color: .accentHot.opacity(0.24), size: 300, start: .init(x: 150, y: 250), end: .init(x: 80, y: 300), duration: 18)
            orb(color: .accentAmber.opacity(0.20), size: 230, start: .init(x: -100, y: 260), end: .init(x: -20, y: 320), duration: 20)
            orb(color: .accentBlue.opacity(0.18), size: 200, start: .init(x: 30, y: -80), end: .init(x: -40, y: -20), duration: 22)

            ArcadeMesh()
                .opacity(0.42)

            LinearGradient(
                colors: [Color.white.opacity(0.04), Color.clear, Color.black.opacity(0.24)],
                startPoint: .top,
                endPoint: .center
            )

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.44)],
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

private struct ArcadeMesh: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Path { path in
                    let spacing: CGFloat = 30
                    let width = proxy.size.width
                    let height = proxy.size.height

                    for x in stride(from: -height, through: width + height, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x - height, y: height))
                    }

                    for x in stride(from: 0, through: width + height, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + height, y: height))
                    }
                }
                .stroke(Color.white.opacity(0.03), lineWidth: 1)

                LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.04), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
    }
}
