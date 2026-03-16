import SwiftUI

struct GameSetupView: View {
    let gameType: GameType

    @State private var selectedMode: PlayerMode
    @State private var playerNames = ["Player 1", "Player 2", "Player 3", "Player 4"]
    @State private var showHowTo = false
    @State private var isPlaying = false

    init(gameType: GameType) {
        self.gameType = gameType
        _selectedMode = State(initialValue: gameType.supportedModes.first ?? .solo)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                infoChips
                howToSection
                modeSelector

                if selectedMode != .solo {
                    playerNamesSection
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(16)
        }
        .background(AmbientBackground())
        .navigationTitle("Setup")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                isPlaying = true
            } label: {
                Label("Start Game", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryCTAButtonStyle())
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 14)
            .background(Color.black.opacity(0.08))
            .accessibilityLabel("Start Game")
            .accessibilityHint("Launches \(gameType.displayName)")
        }
        .fullScreenCover(isPresented: $isPlaying) {
            GameDestinationView(config: configuration)
                .preferredColorScheme(.dark)
        }
    }

    private var configuration: GameConfiguration {
        GameConfiguration(
            gameType: gameType,
            playerMode: selectedMode,
            playerNames: playerNames
        )
    }

    private var header: some View {
        GlassCard(cornerRadius: 28) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentPrimary, Color.accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: gameType.iconName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Color.white)
                                .accessibilityLabel(gameType.displayName)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(gameType.displayName)
                            .font(.resultTitle)
                            .foregroundStyle(Color.textPrimary)

                        Text(gameType.description)
                            .font(.bodyLarge)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()
                }

                Text("Choose your crew, skim the rules, then fire it up.")
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var infoChips: some View {
        HStack(spacing: 10) {
            chip(text: gameType.difficulty.displayName, tint: .accentAmber)
            chip(text: gameType.multiplayerTip, tint: .accentSecondary)
        }
    }

    private func chip(text: String, tint: Color) -> some View {
        Text(text)
            .font(.monoSmall)
            .foregroundStyle(Color.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(0.16))
            .overlay(
                Capsule().stroke(tint.opacity(0.5), lineWidth: 1)
            )
            .clipShape(Capsule())
    }

    private var howToSection: some View {
        DisclosureGroup(isExpanded: $showHowTo) {
            Text(gameType.multiplayerTip)
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
                .padding(.top, 8)
        } label: {
            Text("How to play")
                .font(.sectionTitle)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }

    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Players")
                .font(.sectionTitle)
                .foregroundStyle(Color.textPrimary)

            PlayerModeSelector(modes: gameType.supportedModes, selected: $selectedMode)
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }

    private var playerNamesSection: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Player Names")
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textPrimary)

                ForEach(0..<selectedMode.playerCount, id: \.self) { index in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.playerColor(for: index))
                            .frame(width: 10, height: 10)

                        TextField("", text: $playerNames[index])
                            .font(.bodyLarge)
                            .foregroundStyle(Color.textPrimary)
                            .textInputAutocapitalization(.words)
                            .lineLimit(1)
                            .accessibilityLabel("Player \(index + 1) name")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.inkPanel.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.playerColor(for: index).opacity(0.4), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}

struct GameDestinationView: View {
    let config: GameConfiguration

    var body: some View {
        Group {
            switch config.gameType {
            case .stopwatch:
                StopwatchGameView(config: config)
            case .colorFlash:
                ColorFlashGameView(config: config)
            case .quickTap:
                QuickTapGameView(config: config)
            case .sequenceMemory:
                SequenceMemoryGameView(config: config)
            case .colorSort:
                ColorSortGameView(config: config)
            case .gridReaction:
                GridReactionGameView(config: config)
            case .reactionDuel:
                ReactionDuelGameView(config: config)
            case .colorBattle:
                ColorBattleGameView(config: config)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
