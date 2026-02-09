import SwiftUI

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
        self
            .padding()
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
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
}
