import SwiftUI

/// Small badge indicating premium content
struct UnlockBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.unlockBadge)
            .clipShape(Capsule())
            .accessibilityLabel("Premium feature")
    }
}
