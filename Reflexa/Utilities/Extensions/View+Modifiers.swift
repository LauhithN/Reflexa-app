import SwiftUI

/// Button style with subtle press feedback for card-based navigation
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.984 : 1.0)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .shadow(
                color: Color.black.opacity(configuration.isPressed ? 0.2 : 0.28),
                radius: configuration.isPressed ? 8 : 16,
                y: configuration.isPressed ? 3 : 9
            )
            .animation(.spring(response: 0.26, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

/// Button style used for prominent call-to-action actions
struct PrimaryCTAButtonStyle: ButtonStyle {
    var tint: Color = .accentPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyLarge.weight(.semibold))
            .foregroundStyle(Color.black.opacity(0.82))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [tint, tint.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: tint.opacity(configuration.isPressed ? 0.18 : 0.35), radius: configuration.isPressed ? 6 : 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/// Button style used for secondary actions
struct SecondaryCTAButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyLarge.weight(.semibold))
            .foregroundStyle(Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cardBackground.opacity(0.9))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.strokeSubtle, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/// Shared in-game chrome with guaranteed exit affordance and optional rules recall.
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
                GeometryReader { proxy in
                    HStack {
                        scaffoldButton(
                            icon: "xmark",
                            accessibilityLabel: "Exit \(title)",
                            action: onExit
                        )
                        .accessibilitySortPriority(1000)
                        .allowsHitTesting(true)

                        Spacer()

                        if gameType != nil {
                            scaffoldButton(
                                icon: "questionmark",
                                accessibilityLabel: "How to play \(title)",
                                action: {
                                    onHowToPlayVisibilityChanged?(true)
                                    withAnimation(reduceMotion ? .linear(duration: 0.1) : .easeOut(duration: 0.2)) {
                                        showHowToPlay = true
                                    }
                                }
                            )
                            .allowsHitTesting(true)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, proxy.safeAreaInsets.top + 8)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            .overlay {
                if showHowToPlay, let gameType {
                    HowToPlayOverlay(gameType: gameType) {
                        onHowToPlayVisibilityChanged?(false)
                        withAnimation(reduceMotion ? .linear(duration: 0.1) : .easeOut(duration: 0.2)) {
                            showHowToPlay = false
                        }
                    }
                    .zIndex(30)
                }
            }
    }

    private func scaffoldButton(
        icon: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.38))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibleTapTarget()
        .accessibilityLabel(accessibilityLabel)
    }
}

extension View {
    /// Applies 180-degree rotation for bottom players in multiplayer
    func rotatedForPlayer(_ playerIndex: Int, mode: PlayerMode) -> some View {
        self.rotationEffect(shouldRotate(playerIndex: playerIndex, mode: mode) ? .degrees(180) : .zero)
    }

    private func shouldRotate(playerIndex: Int, mode: PlayerMode) -> Bool {
        switch mode {
        case .solo:
            return false
        case .twoPlayer:
            return playerIndex == 1
        case .fourPlayer:
            return playerIndex >= 2
        }
    }

    /// Standard card styling
    func cardStyle() -> some View {
        glassCard()
    }

    /// Elevated card styling used across modernized screens
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.elevatedCard.opacity(0.96), Color.cardBackground.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.strokeSubtle, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.34), radius: 18, y: 10)
    }

    /// Applies the shared ambient background.
    func screenBackground() -> some View {
        self.background(AmbientBackground())
    }

    /// Minimum 44x44 touch target
    func accessibleTapTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
    }

    /// Conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Dismiss the view when the app goes to background during an active game
    func dismissOnBackground(dismiss: DismissAction, isActive: Bool) -> some View {
        self.onChange(of: isActive) { _, _ in }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                if isActive {
                    dismiss()
                }
            }
    }

    /// Adds a shared top chrome for active game screens.
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
}
