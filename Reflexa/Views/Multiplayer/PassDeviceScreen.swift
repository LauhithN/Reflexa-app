import SwiftUI

struct PassDeviceScreen: View {
    let playerName: String
    let playerColor: Color
    let onReady: () -> Void

    @State private var countdown: Int?

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 24) {
                Spacer()

                GlassCard(cornerRadius: 32) {
                    VStack(spacing: 18) {
                        BrandMark(size: 78)

                        PulseOrb(color: playerColor, size: 132, pulseScale: 1.22, pulseDuration: 1.6)

                        Text("\(playerName)'s Turn")
                            .font(.resultTitle)
                            .foregroundStyle(playerColor)
                            .lineLimit(1)

                        Text("Pass the phone, keep the screen secret, then jump in when everyone is set.")
                            .font(.bodyLarge)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)

                        Button {
                            HapticManager.shared.light()
                            startCountdown()
                        } label: {
                            Text("Tap When Ready")
                        }
                        .buttonStyle(PrimaryCTAButtonStyle(tint: playerColor))
                        .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity)
                }

                Spacer()
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

struct TurnBasedStageContainer<Content: View>: View {
    let roundTitle: String
    let subtitle: String?
    let activePlayerName: String
    let activePlayerColor: Color
    let players: [PlayerResult]
    let activePlayerIndex: Int
    let showPassDevice: Bool
    let onReady: () -> Void
    let content: Content

    init(
        roundTitle: String,
        subtitle: String? = nil,
        activePlayerName: String,
        activePlayerColor: Color,
        players: [PlayerResult],
        activePlayerIndex: Int,
        showPassDevice: Bool,
        onReady: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.roundTitle = roundTitle
        self.subtitle = subtitle
        self.activePlayerName = activePlayerName
        self.activePlayerColor = activePlayerColor
        self.players = players
        self.activePlayerIndex = activePlayerIndex
        self.showPassDevice = showPassDevice
        self.onReady = onReady
        self.content = content()
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(roundTitle)
                        .font(.monoSmall)
                        .foregroundStyle(Color.textSecondary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.playerLabel)
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                }

                MultiplayerPlayerPanel(
                    name: activePlayerName,
                    accentColor: activePlayerColor,
                    subtitle: "Turn-Based",
                    headerTrailing: {
                        Text("ACTIVE")
                            .font(.monoSmall)
                            .foregroundStyle(Color.inkPanel)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(activePlayerColor)
                            .clipShape(Capsule())
                    },
                    content: {
                        content
                    }
                )
                .frame(maxHeight: .infinity)

                PlayerScoreboard(players: players, activePlayerIndex: activePlayerIndex)
            }
            .padding(.top, 88)
            .padding(.horizontal, 16)
            .padding(.bottom, 18)

            if showPassDevice {
                PassDeviceScreen(
                    playerName: activePlayerName,
                    playerColor: activePlayerColor,
                    onReady: onReady
                )
            }
        }
    }
}
