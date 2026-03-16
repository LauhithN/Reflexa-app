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

struct PlayStyleSelector: View {
    let styles: [GamePlayStyle]
    @Binding var selected: GamePlayStyle

    var body: some View {
        VStack(spacing: 10) {
            ForEach(styles) { style in
                Button {
                    withAnimation(Spring.snappy) {
                        selected = style
                    }
                } label: {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(style == .simultaneous ? Color.accentSecondary.opacity(0.2) : Color.accentAmber.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: style.iconName)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(style.displayName)
                                .font(.sectionTitle)
                                .foregroundStyle(Color.textPrimary)

                            Text(style.setupLabel)
                                .font(.monoSmall)
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 12)

                        Image(systemName: selected == style ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(selected == style ? Color.white : Color.textTertiary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                selected == style
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.16), Color.cardBackground.opacity(0.92)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.07), Color.cardBackground.opacity(0.82)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(
                                        selected == style
                                        ? Color.white.opacity(0.34)
                                        : Color.strokeSubtle,
                                        lineWidth: 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibleTapTarget()
                .accessibilityLabel(style.displayName)
                .accessibilityValue(selected == style ? "Selected" : "Not selected")
            }
        }
    }
}
