import SwiftUI

struct GameSetupView: View {
    let gameType: GameType

    @State private var selectedMode: PlayerMode
    @State private var isPlaying = false

    init(gameType: GameType) {
        self.gameType = gameType
        _selectedMode = State(initialValue: gameType.supportedModes.first!)
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // MARK: - Icon
            Image(systemName: gameType.iconName)
                .font(.system(size: 56))
                .foregroundStyle(Color.waiting)

            // MARK: - Title and Description
            VStack(spacing: 8) {
                Text(gameType.displayName)
                    .font(.gameTitle)
                    .foregroundStyle(.white)

                Text(gameType.description)
                    .font(.bodyLarge)
                    .foregroundStyle(.gray)
            }

            // MARK: - Player Mode Selector
            if gameType.supportedModes.count > 1 {
                VStack(spacing: 12) {
                    Text("Players")
                        .font(.caption)
                        .foregroundStyle(.gray)

                    PlayerModeSelector(
                        modes: gameType.supportedModes,
                        selected: $selectedMode
                    )
                }
            }

            Spacer()

            // MARK: - Start Button
            Button {
                isPlaying = true
            } label: {
                Text("Start Game")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .background(Color.waiting)
                    .clipShape(Capsule())
            }
            .accessibleTapTarget()
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isPlaying) {
            gameView
        }
    }

    // MARK: - Game View Router

    @ViewBuilder
    private var gameView: some View {
        let config = GameConfiguration(gameType: gameType, playerMode: selectedMode)

        switch gameType {
        case .stopwatch:
            StopwatchGameView(config: config)
        case .colorFlash:
            ColorFlashGameView(config: config)
        case .colorBattle:
            ColorBattleGameView(config: config)
        case .reactionDuel:
            ReactionDuelGameView(config: config)
        case .dailyChallenge:
            DailyChallengeGameView()
        case .quickTap:
            QuickTapGameView(config: config)
        case .soundReflex:
            SoundReflexGameView(config: config)
        case .vibrationReflex:
            VibrationReflexGameView(config: config)
        case .gridReaction:
            GridReactionGameView(config: config)
        }
    }
}
