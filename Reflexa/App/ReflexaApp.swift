import SwiftUI
import SwiftData

@main
struct ReflexaApp: App {
    private let modelContainer: ModelContainer
    private let didFailToLoadData: Bool
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        let schema = Schema([
            GameResult.self,
            PlayerStats.self,
            DailyChallenge.self
        ])

        do {
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            didFailToLoadData = false
        } catch {
            // Fallback to in-memory storage so the app doesn't crash
            let fallback = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
            modelContainer = fallback
            didFailToLoadData = true
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                NavigationStack {
                    HomeView()
                }
                .tint(Color.accentPrimary)
                .overlay(alignment: .top) {
                    if didFailToLoadData {
                        Text("Stats may not be saved this session.")
                            .font(.caption)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.error.opacity(0.9))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            )
                            .padding(.top, 4)
                    }
                }
                .background(Color.appBackground)
                .preferredColorScheme(.dark)
                .task {
                    await StoreService.shared.checkEntitlements()
                    GameCenterService.shared.authenticate()
                }
            } else {
                OnboardingView()
            }
        }
        .modelContainer(modelContainer)
    }
}
