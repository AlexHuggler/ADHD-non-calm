import SwiftUI
import SwiftData

@main
struct SparkDoApp: App {
    @State private var appState: AppState?

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Quest.self,
            SparkTransaction.self,
            Streak.self,
            PowerUp.self,
            DailyChallenge.self,
            PlayerProfile.self,
            Achievement.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none // Set to .automatic for premium iCloud sync
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if let appState {
                    ContentView(appState: appState)
                } else {
                    // Loading state
                    ZStack {
                        SparkTheme.darkBackground.ignoresSafeArea()

                        VStack(spacing: 16) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(SparkTheme.sunshineYellow)

                            Text("SparkDo")
                                .font(SparkTypography.heading(32))
                                .foregroundStyle(SparkTheme.primaryText)

                            ProgressView()
                                .tint(SparkTheme.electricPurple)
                        }
                    }
                    .onAppear {
                        appState = AppState(modelContext: sharedModelContainer.mainContext)
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
