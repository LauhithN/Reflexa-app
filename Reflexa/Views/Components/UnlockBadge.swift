import SwiftUI

/// Small badge indicating premium content
struct UnlockBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .black, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [Color.accentSun, Color.accentHot],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .accessibilityLabel("Premium feature")
    }
}
