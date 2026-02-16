import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                gamesPage.tag(1)
                getStartedPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bolt.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.waiting)

            Text("Reflexy")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.white)

            Text("Test your reflexes.\nChallenge your friends.")
                .font(.bodyLarge)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Page 2: Game Types

    private var gamesPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("9 Game Modes")
                .font(.gameTitle)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 16) {
                gameRow(icon: "stopwatch", title: "Reaction Games", desc: "Color Flash, Sound Reflex, Vibration Reflex")
                gameRow(icon: "hand.tap.fill", title: "Speed Games", desc: "Quick Tap, Grid Reaction, Stopwatch")
                gameRow(icon: "person.2.fill", title: "Multiplayer", desc: "Color Battle, Charge & Release — up to 4 players")
                gameRow(icon: "calendar", title: "Daily Challenge", desc: "One shot per day — beat your best")
            }
            .padding(.horizontal)

            Spacer()
            Spacer()
        }
        .padding()
    }

    // MARK: - Page 3: Get Started

    private var getStartedPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.tap.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.success)

            Text("Ready?")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.white)

            Text("Your reflexes won't test themselves.")
                .font(.bodyLarge)
                .foregroundStyle(.gray)

            Spacer()

            Button {
                hasCompletedOnboarding = true
            } label: {
                Text("Let's Go")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .background(Color.waiting)
                    .clipShape(Capsule())
            }
            .accessibleTapTarget()
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .padding()
    }

    // MARK: - Helper

    private func gameRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.waiting)
                .frame(width: 44, height: 44)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.playerLabel)
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }
}
