import SwiftUI

struct SettingsView: View {
    @State private var storeVM = StoreViewModel()
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                List {
                    Section("Preferences") {
                        Toggle(isOn: $soundEnabled) {
                            HStack {
                                Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .foregroundStyle(soundEnabled ? Color.waiting : .gray)
                                Text("Sound")
                                    .foregroundStyle(.white)
                            }
                        }
                        .tint(Color.waiting)

                        Toggle(isOn: $hapticsEnabled) {
                            HStack {
                                Image(systemName: hapticsEnabled ? "hand.tap.fill" : "hand.raised.slash.fill")
                                    .foregroundStyle(hapticsEnabled ? Color.waiting : .gray)
                                Text("Haptics")
                                    .foregroundStyle(.white)
                            }
                        }
                        .tint(Color.waiting)
                    }

                    Section("Premium") {
                        if storeVM.isUnlocked {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.success)
                                Text("All games unlocked")
                                    .foregroundStyle(.white)
                            }
                        } else {
                            Button {
                                Task { await storeVM.restorePurchases() }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Restore Purchases")
                                }
                            }
                            .accessibleTapTarget()
                        }
                    }

                    Section("About") {
                        HStack {
                            Text("Version")
                                .foregroundStyle(.white)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                                .foregroundStyle(.gray)
                        }
                    }

                    Section("Legal") {
                        Link(destination: URL(string: Constants.privacyPolicyURL)!) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundStyle(Color.waiting)
                                Text("Privacy Policy")
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }

                        Link(destination: URL(string: Constants.termsOfUseURL)!) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundStyle(Color.waiting)
                                Text("Terms of Use")
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }

                    if let error = storeVM.errorMessage {
                        Section {
                            Text(error)
                                .foregroundStyle(Color.error)
                                .font(.caption)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                    .accessibleTapTarget()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
