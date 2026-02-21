import SwiftUI

struct SettingsView: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerSection
                    preferencesSection
                    aboutSection
                    legalSection
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
                    .accessibleTapTarget()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image("Mascot")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.brandPurple.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Reflexa Settings")
                    .font(.playerLabel.weight(.bold))
                    .foregroundStyle(Color.textPrimary)

                Text("Tune sound, haptics, and support options.")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }

    private var preferencesSection: some View {
        settingsSection(title: "Preferences") {
            Toggle(isOn: $soundEnabled) {
                rowLabel(
                    icon: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                    title: "Sound",
                    tint: soundEnabled ? Color.brandYellow : Color.textSecondary
                )
            }
            .tint(Color.brandPurple)

            Divider().overlay(Color.strokeSubtle)

            Toggle(isOn: $hapticsEnabled) {
                rowLabel(
                    icon: hapticsEnabled ? "hand.tap.fill" : "hand.raised.slash.fill",
                    title: "Haptics",
                    tint: hapticsEnabled ? Color.brandYellow : Color.textSecondary
                )
            }
            .tint(Color.brandPurple)
        }
    }

    private var aboutSection: some View {
        settingsSection(title: "About") {
            HStack {
                Text("Version")
                    .font(.playerLabel)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .font(.playerLabel)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    private var legalSection: some View {
        settingsSection(title: "Legal") {
            if let supportURL = validatedLegalURL(Constants.supportURL) {
                Link(destination: supportURL) {
                    legalRow(icon: "questionmark.circle.fill", title: "Contact Support")
                }
            }

            Divider().overlay(Color.strokeSubtle)

            if let privacyURL = validatedLegalURL(Constants.privacyPolicyURL) {
                Link(destination: privacyURL) {
                    legalRow(icon: "hand.raised.fill", title: "Privacy Policy")
                }
            }

            Divider().overlay(Color.strokeSubtle)

            if let termsURL = validatedLegalURL(Constants.termsOfUseURL) {
                Link(destination: termsURL) {
                    legalRow(icon: "doc.text.fill", title: "Terms of Use")
                }
            }
        }
    }

    private func validatedLegalURL(_ rawValue: String) -> URL? {
        guard let url = URL(string: rawValue),
              url.scheme?.lowercased() == "https",
              url.host?.lowercased() == "lauhithn.github.io",
              url.path.hasPrefix("/reflexa-legal-pages/")
        else {
            return nil
        }
        return url
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)

            VStack(spacing: 12) {
                content()
            }
            .padding(14)
            .glassCard(cornerRadius: 16)
        }
    }

    private func rowLabel(icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22)

            Text(title)
                .font(.playerLabel)
                .foregroundStyle(Color.textPrimary)
        }
    }

    private func legalRow(icon: String, title: String) -> some View {
        HStack {
            rowLabel(icon: icon, title: title, tint: Color.brandYellow)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
        }
    }
}
