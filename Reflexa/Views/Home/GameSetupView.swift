import StoreKit
import SwiftUI

struct GameSetupView: View {
    let gameType: GameType

    @State private var selectedMode: PlayerMode
    @State private var isPlaying = false
    @State private var animateIn = false
    @AppStorage("gamesCompletedCount") private var gamesCompletedCount = 0
    @Environment(\.requestReview) private var requestReview

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
                    detailChip(text: "\(gameType.supportedModes.count) mode\(gameType.supportedModes.count == 1 ? "" : "s")", tint: Color.accentPrimary)
                }
            }
            .padding(20)
            .glassCard(cornerRadius: 24)

            if gameType.supportedModes.count > 1 {
                VStack(spacing: 12) {
                    Text("Player Mode")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    PlayerModeSelector(
                        modes: gameType.supportedModes,
                        selected: $selectedMode
                    )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 14)
                .glassCard(cornerRadius: 18)
            }

            Spacer()

            Button {
                isPlaying = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Start Game")
                }
            }
            .buttonStyle(PrimaryCTAButtonStyle(tint: Color.accentPrimary))
            .accessibleTapTarget()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AmbientBackground())
        .navigationBarTitleDisplayMode(.inline)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 12)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                animateIn = true
            }
        }
        .fullScreenCover(isPresented: $isPlaying) {
            gameView
                .howToPlayOverlay(for: gameType)
        }
        .onChange(of: isPlaying) { _, nowPlaying in
            guard !nowPlaying else { return }
            gamesCompletedCount += 1
            if gamesCompletedCount % 3 == 0 {
                requestReview()
            }
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
        case .sequenceMemory:
            SequenceMemoryGameView(config: config)
        case .colorSort:
            ColorSortGameView(config: config)
        case .gridReaction:
            GridReactionGameView(config: config)
        }
    }
}
