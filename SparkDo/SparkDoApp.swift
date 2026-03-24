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
                    // Skeleton loading state
                    ZStack {
                        SparkTheme.darkBackground.ignoresSafeArea()

                        VStack(spacing: 20) {
                            // Skeleton spark counter
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(SparkTheme.cardBackground)
                                .frame(height: 100)
                                .shimmer()

                            // Skeleton challenge card
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(SparkTheme.cardBackground)
                                .frame(height: 120)
                                .shimmer(duration: 2.5)

                            // Skeleton quick actions
                            HStack(spacing: 12) {
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(SparkTheme.cardBackground)
                                        .frame(height: 70)
                                        .shimmer(duration: 3.0)
                                }
                            }

                            // Skeleton streak
                            HStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(SparkTheme.cardBackground)
                                    .frame(width: 140, height: 44)
                                    .shimmer()
                                Spacer()
                            }

                            Spacer()
                        }
                        .padding()
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
