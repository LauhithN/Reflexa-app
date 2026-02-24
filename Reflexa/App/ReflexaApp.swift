import SwiftUI

private struct HapticsEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

private struct SoundEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var hapticsEnabled: Bool {
        get { self[HapticsEnabledKey.self] }
        set { self[HapticsEnabledKey.self] = newValue }
    }

    var soundEnabled: Bool {
        get { self[SoundEnabledKey.self] }
        set { self[SoundEnabledKey.self] = newValue }
    }
}

@main
struct ReflexaApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    NavigationStack {
                        HomeView()
                    }
                } else {
                    OnboardingView()
                }
            }
            .environment(\.hapticsEnabled, hapticsEnabled)
            .environment(\.soundEnabled, soundEnabled)
            .tint(.accentPrimary)
            .preferredColorScheme(.dark)
            .onAppear {
                SoundService.shared.preloadCountdown()
                SoundService.shared.preloadBeep()
            }
        }
    }
}
