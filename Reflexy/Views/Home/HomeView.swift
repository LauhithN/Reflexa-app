import SwiftUI

struct HomeView: View {
    @State private var showStore = false
    @State private var showSettings = false

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
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reflexy")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Test your reflexes")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .padding(.top, 8)

                // MARK: - Free Games Section
                sectionHeader("Free Games")

                VStack(spacing: 12) {
                    ForEach(freeGames) { game in
                        NavigationLink {
                            GameSetupView(gameType: game)
                        } label: {
                            GameCard(gameType: game, isLocked: false) {}
                                .allowsHitTesting(false)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: - Premium Games Section
                HStack(spacing: 8) {
                    sectionHeader("Premium")
                    UnlockBadge()
                }

                VStack(spacing: 12) {
                    ForEach(premiumGames) { game in
                        if isLocked {
                            GameCard(gameType: game, isLocked: true) {
                                showStore = true
                            }
                        } else {
                            NavigationLink {
                                GameSetupView(gameType: game)
                            } label: {
                                GameCard(gameType: game, isLocked: false) {}
                                    .allowsHitTesting(false)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // MARK: - Stats Button
                NavigationLink {
                    StatsView()
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 20))
                        Text("View Stats")
                            .font(.playerLabel)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding()
                    .background(Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .accessibleTapTarget()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.white)
                        .accessibleTapTarget()
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
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.gameTitle)
            .foregroundStyle(.white)
    }
}
