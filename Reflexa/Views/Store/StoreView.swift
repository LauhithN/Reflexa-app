import SwiftUI

/// Paywall / unlock view for premium games
struct StoreView: View {
    @State private var viewModel = StoreViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Unlock All Games")
                        .font(.resultTitle)
                        .foregroundStyle(.white)

                    Text("One-time purchase. No subscriptions.")
                        .font(.bodyLarge)
                        .foregroundStyle(.gray)
                }

                // Premium games list
                VStack(alignment: .leading, spacing: 12) {
                    premiumFeatureRow(icon: "hand.tap.fill", title: "Quick Tap", desc: "Speed tapping challenge")
                    premiumFeatureRow(icon: "speaker.wave.2.fill", title: "Sound Reflex", desc: "React to audio cues")
                    premiumFeatureRow(icon: "iphone.radiowaves.left.and.right", title: "Vibration Reflex", desc: "React to haptic cues")
                    premiumFeatureRow(icon: "square.grid.3x3.fill", title: "Grid Reaction", desc: "Tap the lit square")
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Spacer()

                if viewModel.isUnlocked {
                    Text("Already Unlocked")
                        .font(.bodyLarge)
                        .foregroundStyle(Color.success)
                } else {
                    VStack(spacing: 12) {
                        Button {
                            Task { await viewModel.purchase() }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Unlock for \(viewModel.priceString)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.unlockBadge)
                        .clipShape(Capsule())
                        .padding(.horizontal, 32)
                        .disabled(viewModel.isLoading)
                        .accessibleTapTarget()

                        Button("Restore Purchases") {
                            Task { await viewModel.restorePurchases() }
                        }
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .accessibleTapTarget()
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.error)
                }

                HStack(spacing: 16) {
                    Link("Terms of Use", destination: URL(string: Constants.termsOfUseURL)!)
                    Text("·").foregroundStyle(.gray)
                    Link("Privacy Policy", destination: URL(string: Constants.privacyPolicyURL)!)
                }
                .font(.caption2)
                .foregroundStyle(.gray)

                Button("Close") {
                    dismiss()
                }
                .font(.bodyLarge)
                .foregroundStyle(.gray)
                .padding(.bottom, 32)
                .accessibleTapTarget()
            }
        }
        .task {
            await viewModel.loadProduct()
        }
    }

    private func premiumFeatureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.unlockBadge)
                .frame(width: 32)

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
