import SwiftUI
import SwiftData

@main
struct ReflexlyApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                GameResult.self,
                PlayerStats.self,
                DailyChallenge.self
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .background(Color.appBackground)
            .preferredColorScheme(.dark)
            .task {
                await StoreService.shared.checkEntitlements()
            }
        }
        .modelContainer(modelContainer)
    }
}
