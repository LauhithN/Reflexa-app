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
            VStack(alignment: .leading, spacing: 24) {
                heroHeader
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)

                gamesSection(title: "Game Modes", caption: "Solo · 2 Player · 4 Player", games: allGames)

                gamesSection(title: "Competitive Modes", caption: "Local multiplayer only", games: duelGames)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.accentPrimary)
                        .accessibilityLabel("Lightning bolt")

                    Text("Reflexa")
                        .font(.heroTitle)
                        .foregroundStyle(Color.textPrimary)
                }

                Spacer()

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
                .buttonStyle(CardButtonStyle())
                .accessibilityLabel("Settings")
                .accessibilityHint("Open app settings")
            }

            Text("Test your reflexes with friends or solo.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            HStack {
                Text(hasStopwatchBest ? "⚡ Best: \(Int(bestTime.rounded()))ms" : "⚡ Best: --")
                    .font(.playerLabel)
                    .foregroundStyle(Color.accentPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentPrimary.opacity(0.14))
                    .clipShape(Capsule())
                    .pulseGlow(color: .accentPrimary)

                Spacer(minLength: 0)
            }

            Text(taglines[taglineIndex])
                .font(.playerLabel)
                .foregroundStyle(Color.textSecondary)
                .id(taglineIndex)
                .transition(.opacity)
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

    private func gamesSection(title: String, caption: String, games: [GameType]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.sectionTitle)
                .foregroundStyle(Color.textPrimary)

            Text(caption)
                .font(.monoSmall)
                .foregroundStyle(Color.textSecondary)

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
