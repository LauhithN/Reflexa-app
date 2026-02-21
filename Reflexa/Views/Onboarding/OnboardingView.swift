import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentPage = 0
    @State private var revealHeroLetters = false
    @State private var revealModeCards = false

    private let pages = 3
    private let previewGames: [GameType] = [.stopwatch, .colorFlash, .quickTap, .sequenceMemory, .colorSort, .gridReaction]

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $currentPage) {
                    heroPage.tag(0)
                    modesPreviewPage.tag(1)
                    valuePage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomControls
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .onAppear {
            revealHeroLetters = true
            revealModeCards = true
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            Spacer()

            if currentPage < pages - 1 {
                Button("Skip") {
                    hasCompletedOnboarding = true
                }
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .accessibilityLabel("Skip onboarding")
                .accessibilityHint("Open the home screen")
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 40)
    }

    private var heroPage: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 12)

            PulseOrb(color: .accentPrimary, size: 120, pulseScale: 1.2, pulseDuration: 1.8)

            HStack(spacing: 0) {
                ForEach(Array("Reflexa".enumerated()), id: \.offset) { index, char in
                    Text(String(char))
                        .font(.heroTitle)
                        .foregroundStyle(Color.textPrimary)
                        .opacity(revealHeroLetters ? 1 : 0)
                        .animation(Spring.stagger(index), value: revealHeroLetters)
                }
            }

            Text("Train your reflexes. One tap at a time.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var modesPreviewPage: some View {
        VStack(spacing: 16) {
            Text("Game Modes")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(previewGames.enumerated()), id: \.element.id) { index, game in
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: game.iconName)
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(Color.accentPrimary)

                            Text(game.displayName)
                                .font(.monoSmall)
                                .foregroundStyle(Color.textPrimary)
                                .lineLimit(2)

                            Text(game.supportedModes.count > 1 ? "Solo / Multi" : "Solo")
                                .font(.monoSmall)
                                .foregroundStyle(Color.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                        }
                        .padding(12)
                        .frame(width: 120, height: 100, alignment: .topLeading)
                        .glassCard(cornerRadius: 16)
                        .opacity(revealModeCards ? 1 : 0)
                        .offset(x: revealModeCards ? 0 : 20)
                        .animation(Spring.stagger(index), value: revealModeCards)
                    }
                }
                .padding(.horizontal, 20)
            }

            Text("6 modes. Solo and local multiplayer.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)

            Spacer()
        }
        .padding(.top, 16)
    }

    private var valuePage: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 10)

            GlassCard(cornerRadius: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    featureRow("No account or internet needed")
                    featureRow("Solo and local multiplayer")
                    featureRow("Up to 4 players on one device")
                    featureRow("Pure reflex training, zero ads")
                }
            }

            Button("Let's Go") {
                hasCompletedOnboarding = true
            }
            .buttonStyle(PrimaryCTAButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentSecondary)
                .font(.system(size: 14, weight: .bold))

            Text(text)
                .font(.bodyLarge)
                .foregroundStyle(Color.textPrimary)
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(0..<pages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.accentPrimary : Color.white.opacity(0.2))
                        .frame(width: index == currentPage ? 26 : 8, height: 8)
                        .animation(Spring.snappy, value: currentPage)
                }
            }

            Button {
                if currentPage == pages - 1 {
                    hasCompletedOnboarding = true
                } else {
                    withAnimation(Spring.snappy) {
                        currentPage += 1
                    }
                }
            } label: {
                Text(currentPage == pages - 1 ? "Let's Go" : "Continue")
            }
            .buttonStyle(PrimaryCTAButtonStyle())
            .padding(.horizontal, 20)
        }
    }
}
