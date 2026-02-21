import SwiftUI

/// Horizontal picker for selecting player mode
struct PlayerModeSelector: View {
    let modes: [PlayerMode]
    @Binding var selected: PlayerMode
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) {
                    modeButtons
                }
            } else {
                HStack(spacing: 8) {
                    modeButtons
                }
            }
        }
    }

    @ViewBuilder
    private var modeButtons: some View {
        ForEach(modes) { mode in
            Button {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                    selected = mode
                }
            } label: {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: 4) {
                            Image(systemName: mode.iconName)
                                .font(.system(size: 14, weight: .semibold))
                            Text(mode.displayName)
                                .font(.caption)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: mode.iconName)
                                .font(.system(size: 13, weight: .semibold))
                            Text(mode.displayName)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .foregroundStyle(selected == mode ? Color.black.opacity(0.82) : Color.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(selected == mode ? Color.brandYellow : Color.cardBackground.opacity(0.9))
                        .overlay(
                            Capsule()
                                .stroke(selected == mode ? Color.brandYellowDeep.opacity(0.9) : Color.strokeSubtle, lineWidth: 1)
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
