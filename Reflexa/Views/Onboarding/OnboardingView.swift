import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentPage = 0
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
        VStack(spacing: 24) {
            Spacer(minLength: 18)

            BrandMark(size: 144)

            VStack(spacing: 8) {
                Text("Reflexa")
                    .font(.heroTitle)
                    .foregroundStyle(Color.textPrimary)

                Text("quick games, quick laughs")
                    .font(.heroCaption)
                    .foregroundStyle(Color.accentAmber)
                    .textCase(.lowercase)
            }

            Text("Bright arcade energy, solo reflex drills, and same-phone battles you can launch in seconds.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)

            HStack(spacing: 10) {
                heroFact("1-4 players", tint: .accentSecondary)
                heroFact("8 game modes", tint: .accentPrimary)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var modesPreviewPage: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Pick your vibe")
                    .font(.resultTitle)
                    .foregroundStyle(Color.textPrimary)

                Text("Tiny rounds, loud reactions")
                    .font(.bodyLarge)
                    .foregroundStyle(Color.textSecondary)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(Array(previewGames.enumerated()), id: \.element.id) { index, game in
                    previewCard(for: game, index: index)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 16)
    }

    private var valuePage: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 10)

            GlassCard(cornerRadius: 28) {
                VStack(spacing: 18) {
                    HStack(alignment: .bottom, spacing: 14) {
                        podiumBar(height: 170, color: .player1Color, title: "1st")
                        podiumBar(height: 128, color: .player2Color, title: "2nd")
                        podiumBar(height: 104, color: .player3Color, title: "3rd")
                    }
                    .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 14) {
                        featureRow("No signup, no waiting, no internet needed")
                        featureRow("Solo mode for grind mode")
                        featureRow("Same-device party rounds for 2 or 4")
                        featureRow("Built for quick passes and instant rematches")
                    }
                }
            }

            Button("Start Playing") {
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
                Text(currentPage == pages - 1 ? "Start Playing" : "Continue")
            }
            .buttonStyle(PrimaryCTAButtonStyle())
            .padding(.horizontal, 20)
        }
    }

    private func heroFact(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.monoSmall)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(0.16))
            .overlay(
                Capsule().stroke(tint.opacity(0.45), lineWidth: 1)
            )
            .clipShape(Capsule())
    }

    private func previewCard(for game: GameType, index: Int) -> some View {
        let tint = index.isMultiple(of: 2) ? Color.accentPrimary : Color.accentSecondary
        let accent = index.isMultiple(of: 2) ? Color.accentAmber : Color.accentBlue

        return VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint, accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: game.iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.white)
                )

            Text(game.displayName)
                .font(.playerLabel)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)

            Text(game.supportedModes.count > 1 ? "Solo + Party" : "Solo")
                .font(.monoSmall)
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .topLeading)
        .glassCard(cornerRadius: 20)
        .opacity(revealModeCards ? 1 : 0)
        .offset(y: revealModeCards ? 0 : 16)
        .animation(Spring.stagger(index), value: revealModeCards)
    }

    private func podiumBar(height: CGFloat, color: Color, title: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.monoSmall)
                .foregroundStyle(Color.textPrimary)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.62)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 82, height: height)
        }
    }
}
