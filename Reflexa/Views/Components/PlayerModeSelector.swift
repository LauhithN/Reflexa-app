import SwiftUI

struct PlayerModeSelector: View {
    let modes: [PlayerMode]
    @Binding var selected: PlayerMode

    var body: some View {
        HStack(spacing: 10) {
            ForEach(modes) { mode in
                Button {
                    withAnimation(Spring.snappy) {
                        selected = mode
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 15, weight: .bold))
                        Text(mode.displayName)
                            .font(.playerLabel)
                            .lineLimit(1)
                    }
                    .foregroundStyle(selected == mode ? Color.inkPanel : Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                selected == mode
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color.white, Color.accentAmber.opacity(0.22)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.08), Color.cardBackground.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(selected == mode ? Color.white.opacity(0.65) : Color.strokeSubtle, lineWidth: 1)
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
