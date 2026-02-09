import SwiftUI

struct SettingsView: View {
    @State private var storeVM = StoreViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                List {
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
                            Text("1.0.0")
                                .foregroundStyle(.gray)
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
