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
            VStack(alignment: .leading, spacing: 24) {
                heroHeader
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)

                gamesSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .background(AmbientBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
                .accessibleTapTarget()
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                animateIn = true
            }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(Color.heroGradient)

                Text("Reflexa")
                    .font(.heroTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.textPrimary, Color.accentSecondary.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Test your reaction time with fast-paced rounds.")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                pill(text: "8 modes", tint: Color.accentPrimary)
                pill(text: "Solo + Multiplayer", tint: Color.accentSecondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.elevatedCard.opacity(0.98), Color.cardBackground.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
        )
    }

    private var gamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Modes")
                .font(.sectionTitle)
                .foregroundStyle(Color.textPrimary)

            Text("Pick a mode and start training.")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(Array(allGames.enumerated()), id: \.element.id) { index, game in
                    NavigationLink {
                        destination(for: game)
                    } label: {
                        GameCard(gameType: game)
                    }
                    .buttonStyle(CardButtonStyle())
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 14)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.84)
                            .delay(Double(index) * 0.04),
                        value: animateIn
                    )
                }
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

    private func pill(text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.14))
            .clipShape(Capsule())
    }
}
