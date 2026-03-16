import SwiftUI

struct HomeView: View {
    @AppStorage("bestTime") private var bestTime = 9_999.0

    @State private var showSettings = false
    @State private var taglineIndex = 0
    @State private var animateIn = false

    private let taglines = [
        "How fast are you today?",
        "Focus. React. Improve.",
        "Your reflexes, sharpened.",
        "One tap changes everything.",
        "Challenge a friend."
    ]

    private let allGames: [GameType] = [.stopwatch, .colorFlash, .quickTap, .sequenceMemory, .colorSort, .gridReaction]
    private let duelGames: [GameType] = [.reactionDuel, .colorBattle]

    private let rotateTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    private var hasStopwatchBest: Bool { bestTime < 9_999 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                heroHeader
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)

                gamesSection(title: "Solo Arcade", caption: "Fast drills and personal bests", games: allGames)

                gamesSection(title: "Party Battles", caption: "Local same-device chaos", games: duelGames)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(AmbientBackground())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .preferredColorScheme(.dark)
        }
        .onReceive(rotateTimer) { _ in
            withAnimation(Spring.smooth) {
                taglineIndex = (taglineIndex + 1) % taglines.count
            }
        }
        .onAppear {
            withAnimation(Spring.smooth) {
                animateIn = true
            }
        }
    }

    private var heroHeader: some View {
        GlassCard(cornerRadius: 32) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    BrandMark(size: 78)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reflexa")
                            .font(.heroTitle)
                            .foregroundStyle(Color.textPrimary)

                        Text("quick games, quick laughs")
                            .font(.heroCaption)
                            .foregroundStyle(Color.accentAmber)
                            .textCase(.lowercase)
                    }

                    Spacer()

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(CardButtonStyle())
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Open app settings")
                }

                Text("Party-ready reflex games for solo streaks, couch battles, and one-phone bragging rights.")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: 10) {
                    heroChip(
                        icon: "bolt.fill",
                        text: hasStopwatchBest ? "\(Int(bestTime.rounded()))ms best" : "Set your first best",
                        tint: .accentAmber
                    )

                    heroChip(icon: "person.3.fill", text: "1 to 4 players", tint: .accentSecondary)
                }

                Text(taglines[taglineIndex])
                    .font(.playerLabel)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .id(taglineIndex)
                    .transition(.opacity)
            }
        }
    }

    private func heroChip(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))

            Text(text)
                .lineLimit(1)
        }
        .font(.monoSmall)
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tint.opacity(0.16))
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.5), lineWidth: 1)
        )
        .clipShape(Capsule())
        .pulseGlow(color: tint)
    }

    private func gamesSection(title: String, caption: String, games: [GameType]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.resultTitle)
                    .foregroundStyle(Color.textPrimary)

                Text(caption)
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)
            }

            VStack(spacing: 12) {
                ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                    NavigationLink {
                        GameSetupView(gameType: game)
                    } label: {
                        GameCard(gameType: game)
                    }
                    .buttonStyle(.plain)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 12)
                    .animation(Spring.stagger(index), value: animateIn)
                }
            }
        }
    }
}
