import SwiftUI

/// Paywall / unlock view for premium games
struct StoreView: View {
    @State private var viewModel = StoreViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                heroCard
                featureList
                purchaseArea
                legalArea
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 26)
        }
        .background(AmbientBackground())
        .task {
            await viewModel.loadProduct()
        }
    }

    private var heroCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentSun, Color.accentHot],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("Unlock Premium Lab")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)

            Text("One-time purchase. No subscriptions.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Included Modes")
                .font(.sectionTitle)
                .foregroundStyle(Color.textPrimary)

            premiumFeatureRow(icon: "hand.tap.fill", title: "Quick Tap", desc: "Speed sprint in 10-second rounds")
            premiumFeatureRow(icon: "speaker.wave.2.fill", title: "Sound Reflex", desc: "React to audio cues")
            premiumFeatureRow(icon: "iphone.radiowaves.left.and.right", title: "Vibration Reflex", desc: "React to haptic cues")
            premiumFeatureRow(icon: "square.grid.3x3.fill", title: "Grid Reaction", desc: "Tap the lit square instantly")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassCard(cornerRadius: 18)
    }

    @ViewBuilder
    private var purchaseArea: some View {
        VStack(spacing: 12) {
            if viewModel.isUnlocked {
                Text("Premium already unlocked")
                    .font(.playerLabel)
                    .foregroundStyle(Color.success)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Button {
                    Task { await viewModel.purchase() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Unlock for \(viewModel.priceString)")
                    }
                }
                .buttonStyle(PrimaryCTAButtonStyle(tint: Color.accentSun))
                .disabled(viewModel.isLoading)
                .accessibleTapTarget()

                Button("Restore Purchases") {
                    Task { await viewModel.restorePurchases() }
                }
                .buttonStyle(SecondaryCTAButtonStyle())
                .accessibleTapTarget()
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var legalArea: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: Constants.termsOfUseURL)!)
                Text("·").foregroundStyle(Color.textSecondary)
                Link("Privacy Policy", destination: URL(string: Constants.privacyPolicyURL)!)
            }
            .font(.caption)
            .foregroundStyle(Color.textSecondary)

            Button("Close") {
                dismiss()
            }
            .buttonStyle(SecondaryCTAButtonStyle())
            .accessibleTapTarget()
        }
        .padding(.top, 4)
    }

    private func premiumFeatureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentSun.opacity(0.18))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.accentSun)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.playerLabel)
                    .foregroundStyle(Color.textPrimary)

                Text(desc)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()
        }
    }
}
