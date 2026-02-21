import SwiftUI

struct PassDeviceScreen: View {
    let playerName: String
    let playerColor: Color
    let onReady: () -> Void

    @State private var countdown: Int?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                PulseOrb(color: playerColor, size: 140, pulseScale: 1.22, pulseDuration: 1.6)

                Text("\(playerName)'s Turn")
                    .font(.resultTitle)
                    .foregroundStyle(playerColor)
                    .lineLimit(1)

                Text("Pass the device and get ready")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)

                Button {
                    HapticManager.shared.light()
                    startCountdown()
                } label: {
                    Text("Tap When Ready")
                }
                .buttonStyle(PrimaryCTAButtonStyle(tint: playerColor))
                .padding(.top, 6)
            }
            .padding(.horizontal, 24)

            if let countdown {
                CountdownOverlay(value: countdown)
            }
        }
        .transition(.opacity)
    }

    private func startCountdown() {
        guard countdown == nil else { return }
        countdown = 3

        Task { @MainActor in
            for value in stride(from: 2, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                countdown = value
            }
            try? await Task.sleep(for: .milliseconds(350))
            onReady()
        }
    }
}
