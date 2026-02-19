import SwiftUI

@main
struct ReflexaApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            appContent
        }
    }

    @ViewBuilder
    private var appContent: some View {
        if hasCompletedOnboarding {
            NavigationStack {
                HomeView()
            }
            .tint(Color.accentPrimary)
            .background(Color.appBackground)
            .preferredColorScheme(.dark)
        } else {
            OnboardingView()
        }
    }
}
