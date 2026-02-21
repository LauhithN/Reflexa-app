import SwiftUI

private struct AccessibleTapTargetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(minWidth: 44, minHeight: 44)
    }
}

private struct ReflexaButtonPressModifier: ViewModifier {
    let isPressed: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1)
            .opacity(isPressed ? 0.85 : 1)
            .animation(Spring.instant, value: isPressed)
    }
}

private struct PlayerBorderModifier: ViewModifier {
    let color: Color
    let width: CGFloat

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.9), lineWidth: width)
        )
    }
}

private struct ShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -0.8

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.2), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .rotationEffect(.degrees(20))
                    .offset(x: proxy.size.width * phase)
                }
                .blendMode(.screen)
                .clipped()
                .allowsHitTesting(false)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(Spring.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}

private struct PulseGlowModifier: ViewModifier {
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(animate ? 0.45 : 0.18), radius: animate ? 20 : 8)
            .scaleEffect(animate ? 1.02 : 1)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(Spring.smooth.repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
    }
}

private struct GameScaffoldModifier: ViewModifier {
    let title: String
    let gameType: GameType?
    let onExit: () -> Void
    let onHowToPlayVisibilityChanged: ((Bool) -> Void)?

    @State private var showHowToPlay = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                HStack {
                    Button(action: onExit) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.textPrimary.opacity(0.9))
                    }
                    .accessibleTapTarget()
                    .accessibilityLabel("End Game")
                    .accessibilityHint("Closes the active game")

                    Spacer()

                    if let gameType {
                        Button {
                            onHowToPlayVisibilityChanged?(true)
                            withAnimation(reduceMotion ? Spring.gentle : Spring.snappy) {
                                showHowToPlay = true
                            }
                        } label: {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(Color.textPrimary.opacity(0.9))
                        }
                        .accessibleTapTarget()
                        .accessibilityLabel("How to play")
                        .accessibilityHint("Shows instructions for \(gameType.displayName)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
            .overlay {
                if showHowToPlay, let gameType {
                    HowToPlayOverlay(gameType: gameType) {
                        onHowToPlayVisibilityChanged?(false)
                        withAnimation(reduceMotion ? Spring.gentle : Spring.snappy) {
                            showHowToPlay = false
                        }
                    }
                    .zIndex(50)
                }
            }
    }
}

extension View {
    func accessibleTapTarget() -> some View {
        modifier(AccessibleTapTargetModifier())
    }

    func reflexaButtonPress(_ isPressed: Bool) -> some View {
        modifier(ReflexaButtonPressModifier(isPressed: isPressed))
    }

    func playerBorder(color: Color, width: CGFloat = 2) -> some View {
        modifier(PlayerBorderModifier(color: color, width: width))
    }

    func shimmerEffect() -> some View {
        modifier(ShimmerModifier())
    }

    func pulseGlow(color: Color) -> some View {
        modifier(PulseGlowModifier(color: color))
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    func gameScaffold(
        title: String,
        gameType: GameType? = nil,
        onHowToPlayVisibilityChanged: ((Bool) -> Void)? = nil,
        onExit: @escaping () -> Void
    ) -> some View {
        modifier(
            GameScaffoldModifier(
                title: title,
                gameType: gameType,
                onExit: onExit,
                onHowToPlayVisibilityChanged: onHowToPlayVisibilityChanged
            )
        )
    }

    func dismissOnBackground(dismiss: DismissAction, isActive: Bool) -> some View {
        onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if isActive {
                dismiss()
            }
        }
    }
}
