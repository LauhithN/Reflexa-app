import SwiftUI

struct WaitingOverlay: View {
    var title: String = "Get Ready..."
    var subtitle: String = "Wait for the trigger"

    var body: some View {
        ZStack {
            AmbientBackground().overlay(Color.black.opacity(0.4))

            VStack(spacing: 20) {
                PulseOrb(color: .accentPrimary, size: 120, pulseScale: 1.2, pulseDuration: 1.5)

                Text(title)
                    .font(.resultTitle)
                    .foregroundStyle(Color.textPrimary)

                Text(subtitle)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}
