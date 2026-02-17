import SwiftUI
import GameKit

struct HomeView: View {
    @State private var showStore = false
    @State private var showSettings = false
    @State private var animateIn = false

    private let freeGames: [GameType] = [
        .stopwatch, .colorFlash, .colorBattle, .reactionDuel, .dailyChallenge
    ]

    private let premiumGames: [GameType] = [
        .quickTap, .soundReflex, .vibrationReflex, .gridReaction
    ]

    private var isLocked: Bool {
        !StoreService.shared.isUnlocked
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                heroHeader
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)

                quickActions
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)

                gamesSection(
                    title: "Core Modes",
                    subtitle: "Play instantly. Improve reaction speed every session.",
                    games: freeGames,
                    premiumSection: false
                )

                gamesSection(
                    title: "Premium Lab",
                    subtitle: isLocked ? "Unlock advanced challenge modes." : "All premium modes unlocked.",
                    games: premiumGames,
                    premiumSection: true
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .background(AmbientBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    GameCenterService.shared.showDashboard()
                } label: {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundStyle(
                            GameCenterService.shared.isAuthenticated
                                ? Color.textPrimary
                                : Color.textSecondary.opacity(0.35)
                        )
                        .padding(10)
                        .background(Color.cardBackground.opacity(0.85))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.strokeSubtle, lineWidth: 1)
                        )
                }
                .disabled(!GameCenterService.shared.isAuthenticated)
                .accessibilityLabel("Game Center")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(Color.textPrimary)
                        .padding(10)
                        .background(Color.cardBackground.opacity(0.85))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.strokeSubtle, lineWidth: 1)
                        )
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showStore) {
            StoreView()
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
            Text("Reflexa")
                .font(.heroTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.textPrimary, Color.accentSecondary.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Train reflexes with fast rounds, ranked progress, and multiplayer pressure.")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                pill(text: "9 modes", tint: Color.accentPrimary)
                pill(text: "Solo + Multiplayer", tint: Color.accentSecondary)
                if isLocked {
                    pill(text: "Premium Available", tint: Color.accentSun)
                }
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

    private var quickActions: some View {
        HStack(spacing: 10) {
            NavigationLink {
                StatsView()
            } label: {
                actionTile(icon: "chart.bar.fill", title: "Stats", subtitle: "Track your best")
            }
            .buttonStyle(CardButtonStyle())

            NavigationLink {
                LeaderboardView()
            } label: {
                actionTile(icon: "trophy.fill", title: "Leaderboard", subtitle: "Personal bests")
            }
            .buttonStyle(CardButtonStyle())

            if isLocked {
                Button {
                    showStore = true
                } label: {
                    actionTile(icon: "sparkles", title: "Unlock", subtitle: "Premium")
                }
                .buttonStyle(CardButtonStyle())
            }
        }
    }

    private func actionTile(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.strokeSubtle, lineWidth: 1)
                )
        )
    }

    private func gamesSection(
        title: String,
        subtitle: String,
        games: [GameType],
        premiumSection: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textPrimary)

                if premiumSection {
                    UnlockBadge()
                }
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 12) {
                ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                    Group {
                        if premiumSection, isLocked {
                            GameCard(gameType: game, isLocked: true) {
                                showStore = true
                            }
                        } else {
                            NavigationLink {
                                GameSetupView(gameType: game)
                            } label: {
                                GameCard(gameType: game, isLocked: false)
                            }
                            .buttonStyle(CardButtonStyle())
                        }
                    }
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
