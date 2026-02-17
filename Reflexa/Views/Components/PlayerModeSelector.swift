import SwiftUI

/// Horizontal picker for selecting player mode
struct PlayerModeSelector: View {
    let modes: [PlayerMode]
    @Binding var selected: PlayerMode

    var body: some View {
        HStack(spacing: 10) {
            ForEach(modes) { mode in
                Button {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        selected = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 14))
                        Text(mode.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .allowsTightening(true)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(selected == mode ? Color.textPrimary : Color.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(selected == mode ? Color.accentPrimary : Color.cardBackground.opacity(0.8))
                            .overlay(
                                Capsule()
                                    .stroke(selected == mode ? .white.opacity(0.18) : Color.strokeSubtle, lineWidth: 1)
                            )
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(CardButtonStyle())
                .frame(maxWidth: .infinity)
                .accessibleTapTarget()
                .accessibilityLabel("\(mode.displayName) mode")
                .accessibilityAddTraits(selected == mode ? .isSelected : [])
            }
        }
    }
}
