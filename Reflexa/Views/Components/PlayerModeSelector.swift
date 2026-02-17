import SwiftUI

/// Horizontal picker for selecting player mode
struct PlayerModeSelector: View {
    let modes: [PlayerMode]
    @Binding var selected: PlayerMode

    var body: some View {
        HStack(spacing: 12) {
            ForEach(modes) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 14))
                        Text(mode.displayName)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(selected == mode ? .white : .gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(selected == mode ? Color.waiting : Color.cardBackground)
                    .clipShape(Capsule())
                }
                .accessibleTapTarget()
                .accessibilityLabel("\(mode.displayName) mode")
                .accessibilityAddTraits(selected == mode ? .isSelected : [])
            }
        }
    }
}
