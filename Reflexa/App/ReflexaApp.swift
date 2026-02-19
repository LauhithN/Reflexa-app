import SwiftUI
import SwiftData

@main
struct ReflexaApp: App {
    private enum DataStoreState {
        case persistent(ModelContainer)
        case inMemoryFallback(ModelContainer)
        case unavailable
    }

    private let dataStoreState: DataStoreState
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
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            dataStoreState = .persistent(container)
        } catch {
            // Fallback to in-memory storage so the app doesn't crash
            do {
                let container = try ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
                )
                dataStoreState = .inMemoryFallback(container)
            } catch {
                // Last resort: render a startup failure screen instead of crashing.
                dataStoreState = .unavailable
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            switch dataStoreState {
            case .persistent(let modelContainer):
                appContent(showDataWarning: false)
                    .modelContainer(modelContainer)
            case .inMemoryFallback(let modelContainer):
                appContent(showDataWarning: true)
                    .modelContainer(modelContainer)
            case .unavailable:
                DataStoreUnavailableView()
            }
        }
    }

    @ViewBuilder
    private func appContent(showDataWarning: Bool) -> some View {
        if hasCompletedOnboarding {
            NavigationStack {
                HomeView()
            }
            .tint(Color.accentPrimary)
            .overlay(alignment: .top) {
                if showDataWarning {
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
        } else {
            OnboardingView()
        }
    }
}

private struct DataStoreUnavailableView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.error)

            Text("Reflexa could not start")
                .font(.resultTitle)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            Text("Local data failed to initialize. Restart the app and free some storage or memory, then try again.")
                .font(.bodyLarge)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AmbientBackground())
        .preferredColorScheme(.dark)
    }
}
