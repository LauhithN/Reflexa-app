import SwiftUI

struct GameSetupView: View {
    let gameType: GameType

    @State private var selectedMode: PlayerMode
    @State private var isPlaying = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    init(gameType: GameType) {
        self.gameType = gameType
        _selectedMode = State(initialValue: gameType.supportedModes.first ?? .solo)
    }

    var body: some View {
        VStack(spacing: 18) {
            headerTile

            if availableModes.count > 1 {
                modeTile
            }

            if voiceOverBlocksStart {
                Text("Unavailable with VoiceOver for this mode.")
                    .font(.caption)
                    .foregroundStyle(Color.error)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .glassCard(cornerRadius: 14)
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
                .background(Color.black.opacity(0.18))
        }
        .onAppear {
            if !availableModes.contains(selectedMode), let fallbackMode = availableModes.first {
                selectedMode = fallbackMode
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

    private var headerTile: some View {
        HStack(spacing: 12) {
            iconBadge

            VStack(alignment: .leading, spacing: 4) {
                Text(gameType.displayName)
                    .font(.resultTitle)
                    .foregroundStyle(Color.textPrimary)
                Text("Ready")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.cardBackground.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
        )
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(Color.brandYellow.opacity(0.2))
                .frame(width: 62, height: 62)
            Image(systemName: gameType.iconName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.brandYellow)
        }
        .overlay(
            Circle()
                .stroke(Color.brandYellow.opacity(0.35), lineWidth: 1)
        )
    }

    private var modeTile: some View {
        VStack(spacing: 10) {
            Text("Mode")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            PlayerModeSelector(
                modes: availableModes,
                selected: $selectedMode
            )
        }
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 16)
    }

    private var startGameButton: some View {
        Button {
            guard canStartGame else { return }
            isPlaying = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Start")
            }
        }
        .buttonStyle(PrimaryCTAButtonStyle(tint: Color.accentPrimary))
        .accessibleTapTarget()
        .disabled(!canStartGame)
        .opacity(canStartGame ? 1 : 0.5)
    }

    private var availableModes: [PlayerMode] {
        guard !voiceOverEnabled else { return supportsSoloMode ? [.solo] : gameType.supportedModes }
        return gameType.supportedModes
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
