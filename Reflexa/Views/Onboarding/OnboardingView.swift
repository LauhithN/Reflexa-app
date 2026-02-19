import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            topBar

            TabView(selection: $currentPage) {
                page(
                    icon: "bolt.fill",
                    title: "Welcome to Reflexa",
                    subtitle: "Modern reflex training in short, addictive rounds.",
                    accent: Color.accentPrimary
                ) {
                    featureRow(icon: "sparkles", text: "Fast startup, instant play")
                    featureRow(icon: "person.2.fill", text: "Solo and local multiplayer")
                    featureRow(icon: "chart.line.uptrend.xyaxis", text: "Track progress over time")
                }
                .tag(0)

                page(
                    icon: "scope",
                    title: "Challenge Modes",
                    subtitle: "Precision, speed, and pressure with unique mechanics.",
                    accent: Color.accentSecondary
                ) {
                    featureRow(icon: "clock", text: "Stopwatch precision")
                    featureRow(icon: "eye.fill", text: "Color Flash decoy reaction")
                    featureRow(icon: "hand.tap.fill", text: "Quick Tap speed sprint")
                    featureRow(icon: "square.grid.3x3.fill", text: "Grid Reaction focus test")
                }
                .tag(1)

                page(
                    icon: "trophy.fill",
                    title: "Set New Bests",
                    subtitle: "Compete against yourself daily and beat your personal best.",
                    accent: Color.accentHot
                ) {
                    featureRow(icon: "calendar", text: "Daily challenge streaks")
                    featureRow(icon: "medal.fill", text: "Personal best tracking")
                    featureRow(icon: "gamecontroller.fill", text: "9 unique game modes")
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            bottomControls
        }
        .background(AmbientBackground())
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack {
            Spacer()

            if currentPage < totalPages - 1 {
                Button("Skip") {
                    hasCompletedOnboarding = true
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var bottomControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.accentPrimary : Color.white.opacity(0.2))
                        .frame(width: index == currentPage ? 26 : 8, height: 8)
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: currentPage)
                }
            }

            Button {
                if currentPage == totalPages - 1 {
                    hasCompletedOnboarding = true
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        currentPage += 1
                    }
                }
            } label: {
                Text(currentPage == totalPages - 1 ? "Start Playing" : "Continue")
            }
            .buttonStyle(PrimaryCTAButtonStyle(tint: Color.accentPrimary))
            .accessibleTapTarget()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
    }

    private func page<Content: View>(
        icon: String,
        title: String,
        subtitle: String,
        accent: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 20) {
            Spacer(minLength: 16)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: icon)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .glassCard(cornerRadius: 20)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.accentPrimary)
                .frame(width: 22)

            Text(text)
                .font(.playerLabel)
                .foregroundStyle(Color.textPrimary)
        }
    }
}
