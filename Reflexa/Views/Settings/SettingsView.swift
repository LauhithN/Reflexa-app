import SwiftUI

struct SettingsView: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    @State private var showResetAlert = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    appPreview
                    togglesCard
                    aboutCard
                    legalCard
                    resetCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
            .background(AmbientBackground())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .tint(.accentPrimary)
        .alert("Reset best scores?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetBestScores()
            }
        } message: {
            Text("This clears all local best scores on this device.")
        }
    }

    private var appPreview: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appBackground)
                    .frame(width: 64, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.strokeSubtle, lineWidth: 1)
                    )

                Image(systemName: "bolt.fill")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(Color.accentPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Reflexa")
                    .font(.sectionTitle)
                    .foregroundStyle(Color.textPrimary)
                Text("Minimal local multiplayer reflex training")
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }

    private var togglesCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(spacing: 12) {
                Toggle(isOn: $soundEnabled) {
                    settingRow(icon: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill", title: "Sound")
                }

                Divider().overlay(Color.strokeSubtle)

                Toggle(isOn: $hapticsEnabled) {
                    settingRow(icon: hapticsEnabled ? "hand.tap.fill" : "hand.raised.slash.fill", title: "Haptics")
                }
            }
        }
    }

    private var aboutCard: some View {
        GlassCard(cornerRadius: 18) {
            HStack {
                Text("Version")
                    .font(.playerLabel)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .font(.monoSmall)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var legalCard: some View {
        GlassCard(cornerRadius: 18) {
            VStack(spacing: 12) {
                if let supportURL = URL(string: Constants.supportURL) {
                    legalRow(icon: "questionmark.circle.fill", title: "Support", url: supportURL)
                }
                if let privacyURL = URL(string: Constants.privacyPolicyURL) {
                    legalRow(icon: "hand.raised.fill", title: "Privacy Policy", url: privacyURL)
                }
                if let termsURL = URL(string: Constants.termsOfUseURL) {
                    legalRow(icon: "doc.text.fill", title: "Terms of Use", url: termsURL)
                }
            }
        }
    }

    private var resetCard: some View {
        Button {
            showResetAlert = true
        } label: {
            Text("Reset Best Scores")
                .font(.sectionTitle)
                .foregroundStyle(Color.destructive)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.destructive.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Reset Best Scores")
        .accessibilityHint("Clears local score history")
    }

    private func settingRow(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentPrimary)
                .frame(width: 20)
            Text(title)
                .font(.playerLabel)
                .foregroundStyle(Color.textPrimary)
        }
    }

    private func legalRow(icon: String, title: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                settingRow(icon: icon, title: title)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .accessibilityLabel(title)
        .accessibilityHint("Opens in browser")
    }

    private func resetBestScores() {
        let keys = [
            "bestTime",
            "bestQuickTap",
            "bestGridReaction",
            "bestReactionDuel",
            "bestColorFlash",
            "bestSequenceMemory",
            "bestColorSort"
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}
