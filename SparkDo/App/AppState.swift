import SwiftUI
import SwiftData

@Observable
final class AppState {
    let modelContext: ModelContext

    // Services
    let sparkEngine: SparkEngine
    let streakManager: StreakManager
    let challengeGenerator: ChallengeGenerator
    let questSurfacing: QuestSurfacingEngine
    let storeKit: StoreKitManager

    // State
    var profile: PlayerProfile
    var streak: Streak
    var todayChallenge: DailyChallenge

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Initialize services
        self.sparkEngine = SparkEngine(modelContext: modelContext)
        self.streakManager = StreakManager(modelContext: modelContext)
        self.challengeGenerator = ChallengeGenerator(modelContext: modelContext)
        self.questSurfacing = QuestSurfacingEngine(modelContext: modelContext)
        self.storeKit = StoreKitManager()

        // Load or create profile
        let profileDescriptor = FetchDescriptor<PlayerProfile>()
        if let existingProfile = try? modelContext.fetch(profileDescriptor).first {
            self.profile = existingProfile
        } else {
            let newProfile = PlayerProfile()
            modelContext.insert(newProfile)
            self.profile = newProfile
        }

        // Load or create streak
        self.streak = streakManager.getOrCreateStreak()

        // Load or create today's challenge
        self.todayChallenge = challengeGenerator.getTodaysChallenge()

        // Sync settings
        SoundManager.shared.isEnabled = profile.soundEnabled
        HapticsManager.isEnabled = profile.hapticsEnabled

        // Check for missed streak days
        streakManager.checkForMissedDays(streak: streak)

        // Reset daily sprint counter if needed
        profile.resetDailySprintsIfNeeded()

        // Sync premium status
        Task { @MainActor in
            await storeKit.checkPurchaseStatus()
            if storeKit.isPurchased {
                profile.isPremium = true
            }
        }

        // Seed achievements if empty
        seedAchievementsIfNeeded()

        // Seed power-ups if empty
        seedPowerUpsIfNeeded()

        // Preload sounds
        SoundManager.shared.preloadSounds()
    }

    // MARK: - Seeding

    private func seedAchievementsIfNeeded() {
        let descriptor = FetchDescriptor<Achievement>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0

        guard count == 0 else { return }

        for def in Achievement.definitions {
            let achievement = Achievement(
                key: def.0,
                name: def.1,
                description: def.2,
                rarity: def.3,
                iconName: def.4
            )
            modelContext.insert(achievement)
        }
    }

    private func seedPowerUpsIfNeeded() {
        let descriptor = FetchDescriptor<PowerUp>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0

        guard count == 0 else { return }

        for def in PowerUp.defaultPowerUps {
            let powerUp = PowerUp(
                name: def.0,
                description: def.1,
                category: def.2,
                sparkCost: def.3,
                colorHex: def.4,
                iconName: def.5
            )
            modelContext.insert(powerUp)
        }
    }

    // MARK: - Today's Sparks

    var todaySparks: Int {
        sparkEngine.todaySparks()
    }
}
