import SwiftUI

/// Button style with subtle press feedback for card-based navigation
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.12 : 0.2), radius: configuration.isPressed ? 6 : 14, y: configuration.isPressed ? 2 : 8)
            .animation(.spring(response: 0.26, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

/// Button style used for prominent call-to-action actions
struct PrimaryCTAButtonStyle: ButtonStyle {
    var tint: Color = .accentPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyLarge.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [tint, tint.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
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
            .background(Color.cardBackground.opacity(0.76))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.strokeSubtle, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
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
                            colors: [Color.elevatedCard.opacity(0.96), Color.cardBackground.opacity(0.82)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.strokeSubtle, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.28), radius: 16, y: 8)
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
}
