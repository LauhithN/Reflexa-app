import SwiftUI

struct GameSetupView: View {
    let gameType: GameType

    @State private var selectedMode: PlayerMode
    @State private var isPlaying = false
    @State private var animateIn = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    init(gameType: GameType) {
        self.gameType = gameType
        _selectedMode = State(initialValue: gameType.supportedModes.first ?? .solo)
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 14) {
                iconBadge

                Text(gameType.displayName)
                    .font(.resultTitle)
                    .foregroundStyle(Color.textPrimary)

                Text(gameType.description)
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    detailChip(text: "\(availableModes.count) mode\(availableModes.count == 1 ? "" : "s")", tint: Color.accentPrimary)
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 24)

            if voiceOverEnabled && supportsSoloMode && availableModes.count < gameType.supportedModes.count {
                Text("VoiceOver is active, so local multiplayer modes are hidden for this game.")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .glassCard(cornerRadius: 14)
            }

            if voiceOverBlocksStart {
                Text("This game requires simultaneous local touch input and is unavailable while VoiceOver is on.")
                    .font(.caption)
                    .foregroundStyle(Color.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .glassCard(cornerRadius: 14)
            }

            if availableModes.count > 1 {
                VStack(spacing: 12) {
                    Text("Player Mode")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    PlayerModeSelector(
                        modes: availableModes,
                        selected: $selectedMode
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 14)
                .glassCard(cornerRadius: 18)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AmbientBackground())
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            startGameButton
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color.black.opacity(0.2))
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 12)
        .onAppear {
            if !availableModes.contains(selectedMode), let fallbackMode = availableModes.first {
                selectedMode = fallbackMode
            }
            withAnimation(.easeOut(duration: 0.35)) {
                animateIn = true
            }
        }
        .onChange(of: voiceOverEnabled) { _, _ in
            if !availableModes.contains(selectedMode), let fallbackMode = availableModes.first {
                selectedMode = fallbackMode
            }
        }
        .fullScreenCover(isPresented: $isPlaying) {
            GameDestinationView(gameType: gameType, playerMode: selectedMode)
                .howToPlayOverlay(for: gameType)
        }
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentPrimary.opacity(0.95), Color.accentSecondary.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 94, height: 94)

            Image(systemName: gameType.iconName)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func detailChip(text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.16))
            .clipShape(Capsule())
    }

    private var startGameButton: some View {
        Button {
            guard canStartGame else { return }
            isPlaying = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Start Game")
            }
        }
        .buttonStyle(PrimaryCTAButtonStyle(tint: Color.accentPrimary))
        .accessibleTapTarget()
        .disabled(!canStartGame)
        .opacity(canStartGame ? 1 : 0.55)
    }
    
    private var availableModes: [PlayerMode] {
        guard voiceOverEnabled else { return gameType.supportedModes }
        return supportsSoloMode ? [.solo] : gameType.supportedModes
    }

    private var supportsSoloMode: Bool {
        gameType.supportedModes.contains(.solo)
    }

    private var voiceOverBlocksStart: Bool {
        voiceOverEnabled && !supportsSoloMode
    }

    private var canStartGame: Bool {
        !voiceOverBlocksStart
    }
}

// MARK: - Game View Router
struct GameDestinationView: View {
    let gameType: GameType
    let playerMode: PlayerMode
    
    @ViewBuilder
    private var gameView: some View {
        let config = GameConfiguration(gameType: gameType, playerMode: playerMode)

        switch gameType {
        case .stopwatch:
            StopwatchGameView(config: config)
        case .colorFlash:
            ColorFlashGameView(config: config)
        case .colorBattle:
            ColorBattleGameView(config: config)
        case .reactionDuel:
            ReactionDuelGameView(config: config)
        case .quickTap:
            QuickTapGameView(config: config)
        case .sequenceMemory:
            SequenceMemoryGameView(config: config)
        case .colorSort:
            ColorSortGameView(config: config)
        case .gridReaction:
            GridReactionGameView(config: config)
        }
    }

    var body: some View {
        gameView
    }
}
