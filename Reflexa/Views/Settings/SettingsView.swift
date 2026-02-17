import SwiftUI

struct SettingsView: View {
    @State private var storeVM = StoreViewModel()
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    preferencesSection
                    premiumSection
                    aboutSection
                    legalSection

                    if let error = storeVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
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

    private var preferencesSection: some View {
        settingsSection(title: "Preferences") {
            Toggle(isOn: $soundEnabled) {
                rowLabel(
                    icon: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                    title: "Sound",
                    tint: soundEnabled ? Color.accentPrimary : Color.textSecondary
                )
            }
            .tint(Color.accentPrimary)

            Divider().overlay(Color.strokeSubtle)

            Toggle(isOn: $hapticsEnabled) {
                rowLabel(
                    icon: hapticsEnabled ? "hand.tap.fill" : "hand.raised.slash.fill",
                    title: "Haptics",
                    tint: hapticsEnabled ? Color.accentPrimary : Color.textSecondary
                )
            }
            .tint(Color.accentPrimary)
        }
    }

    private var premiumSection: some View {
        settingsSection(title: "Premium") {
            if storeVM.isUnlocked {
                HStack {
                    rowLabel(icon: "checkmark.seal.fill", title: "All games unlocked", tint: Color.success)
                    Spacer()
                }
            } else {
                Button {
                    Task { await storeVM.restorePurchases() }
                } label: {
                    HStack {
                        rowLabel(icon: "arrow.clockwise", title: "Restore Purchases", tint: Color.accentPrimary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .accessibleTapTarget()
            }
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
            Link(destination: URL(string: Constants.privacyPolicyURL)!) {
                legalRow(icon: "hand.raised.fill", title: "Privacy Policy")
            }

            Divider().overlay(Color.strokeSubtle)

            Link(destination: URL(string: Constants.termsOfUseURL)!) {
                legalRow(icon: "doc.text.fill", title: "Terms of Use")
            }
        }
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
            rowLabel(icon: icon, title: title, tint: Color.accentPrimary)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
        }
    }
}
