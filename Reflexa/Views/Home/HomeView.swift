import SwiftUI

struct HomeView: View {
    @State private var showSettings = false
    @State private var animateIn = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let allGames: [GameType] = [
        .stopwatch, .colorFlash, .quickTap, .sequenceMemory,
        .colorBattle, .reactionDuel, .colorSort, .gridReaction
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                topBar
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)

                titleBlock
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)

                gameGrid
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(AmbientBackground())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                animateIn = true
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            progressBar

            Spacer(minLength: 0)

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(Color.cardBackground.opacity(0.95))
                            .overlay(
                                Circle()
                                    .stroke(Color.strokeSubtle, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(CardButtonStyle())
            .accessibilityLabel("Settings")
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(Color.brandYellow)
                .frame(width: 82, height: 6)

            Capsule()
                .fill(Color.white.opacity(0.14))
                .frame(width: 64, height: 6)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Choose a game")
                    .font(.sectionTitle.weight(.heavy))
                    .foregroundStyle(Color.textPrimary)

                Image("Mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }

            Text("Tap to play")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var gameGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(Array(allGames.enumerated()), id: \.element.id) { index, game in
                NavigationLink {
                    destination(for: game)
                } label: {
                    GameCard(gameType: game)
                }
                .buttonStyle(CardButtonStyle())
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 12)
                .animation(
                    .spring(response: 0.34, dampingFraction: 0.84)
                        .delay(Double(index) * 0.03),
                    value: animateIn
                )
            }
        }
    }

    private var gridColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: 12)]
        }
        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    @ViewBuilder
    private func destination(for game: GameType) -> some View {
        if shouldBypassSetup(for: game) {
            GameDestinationView(gameType: game, playerMode: .solo)
                .howToPlayOverlay(for: game)
        } else {
            GameSetupView(gameType: game)
        }
    }

    private func shouldBypassSetup(for game: GameType) -> Bool {
        game.supportedModes == [.solo]
    }
}
