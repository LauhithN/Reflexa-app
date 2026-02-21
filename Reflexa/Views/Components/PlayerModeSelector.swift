import SwiftUI

struct PlayerModeSelector: View {
    let modes: [PlayerMode]
    @Binding var selected: PlayerMode

    var body: some View {
        HStack(spacing: 8) {
            ForEach(modes) { mode in
                Button {
                    withAnimation(Spring.snappy) {
                        selected = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 13, weight: .semibold))
                        Text(mode.displayName)
                            .font(.playerLabel)
                            .lineLimit(1)
                    }
                    .foregroundStyle(selected == mode ? Color.white : Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(selected == mode ? Color.accentPrimary : Color.cardBackground)
                            .overlay(
                                Capsule()
                                    .stroke(selected == mode ? Color.accentPrimary.opacity(0.2) : Color.strokeSubtle, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibleTapTarget()
                .accessibilityLabel(mode.displayName)
                .accessibilityAddTraits(selected == mode ? .isSelected : [])
            }
        }
    }
}
