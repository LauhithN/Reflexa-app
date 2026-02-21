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
                    icon: "mascot",
                    title: "Pick. Tap. Repeat.",
                    subtitle: "Fast reflex drills.",
                    accent: Color.brandPurple
                ) {
                    featureRow(icon: "sparkles", text: "Instant start")
                    featureRow(icon: "gamecontroller.fill", text: "8 game modes")
                    featureRow(icon: "person.2.fill", text: "Solo + local multiplayer")
                }
                .tag(0)

                page(
                    icon: "gamecontroller.fill",
                    title: "Speed + Precision",
                    subtitle: "Short rounds. Quick retry.",
                    accent: Color.brandYellowDeep
                ) {
                    featureRow(icon: "clock", text: "Stopwatch")
                    featureRow(icon: "eye.fill", text: "Color Flash")
                    featureRow(icon: "hand.tap.fill", text: "Quick Tap")
                    featureRow(icon: "square.grid.3x3.fill", text: "Grid Reaction")
                }
                .tag(1)

                page(
                    icon: "bolt.circle.fill",
                    title: "Ready?",
                    subtitle: "Train now.",
                    accent: Color.accentHot
                ) {
                    featureRow(icon: "clock.arrow.circlepath", text: "Instant replay")
                    featureRow(icon: "bolt.fill", text: "Track your score")
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
                .accessibleTapTarget()
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
                        .fill(index == currentPage ? Color.brandYellow : Color.white.opacity(0.2))
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

                if icon == "mascot" {
                    Image("Mascot")
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }
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
                .foregroundStyle(Color.brandYellow)
                .frame(width: 22)

            Text(text)
                .font(.playerLabel)
                .foregroundStyle(Color.textPrimary)
        }
    }
}
