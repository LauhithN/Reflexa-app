import SwiftUI

/// Overlay shown during the waiting/anticipation phase before stimulus
struct WaitingOverlay: View {
    let isDark: Bool // true for sound/vibration reflex (no visual cue)

    var body: some View {
        ZStack {
            if isDark {
                Color.black.ignoresSafeArea()
            } else {
                AmbientBackground()
            }

            if !isDark {
                PulsingText(text: "Wait...", color: .waiting)
            }
        }
        .accessibilityLabel("Waiting for stimulus. Do not tap yet.")
    }
}
