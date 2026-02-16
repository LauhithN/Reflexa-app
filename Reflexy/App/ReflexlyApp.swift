import SwiftUI
import SwiftData

@main
struct ReflexlyApp: App {
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
                .overlay(alignment: .top) {
                    if didFailToLoadData {
                        Text("Stats may not be saved this session.")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Capsule())
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
