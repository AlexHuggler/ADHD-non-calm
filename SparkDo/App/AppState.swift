import SwiftUI
import SwiftData

// H3 fix: @MainActor ensures all state mutations happen on Main Thread.
// This class coordinates UI-bound state; all access should be main-actor-isolated.
@MainActor
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

        // M1 fix: Load or create profile with error logging
        let profileDescriptor = FetchDescriptor<PlayerProfile>()
        do {
            if let existingProfile = try modelContext.fetch(profileDescriptor).first {
                self.profile = existingProfile
            } else {
                let newProfile = PlayerProfile()
                modelContext.insert(newProfile)
                self.profile = newProfile
            }
        } catch {
            print("SparkDo [AppState]: Failed to fetch profile: \(error)")
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

        // H3 fix: StoreKit premium check runs async. Since AppState is now @MainActor,
        // the Task inherits main-actor isolation. The profile mutation is safe but may
        // arrive after first render — acceptable for premium status (UI updates reactively).
        Task {
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

        // M8 fix: Sync widget data on launch
        syncWidgetData()
    }

    // MARK: - Seeding

    // M1 fix: Log fetch errors instead of silent try?
    private func seedAchievementsIfNeeded() {
        let descriptor = FetchDescriptor<Achievement>()
        let count: Int
        do {
            count = try modelContext.fetchCount(descriptor)
        } catch {
            print("SparkDo [AppState]: Failed to count achievements: \(error)")
            return
        }

        guard count == 0 else { return }

        // M3 fix: Use labeled struct fields instead of magic tuple indices
        for def in Achievement.definitions {
            let achievement = Achievement(
                key: def.key,
                name: def.name,
                description: def.description,
                rarity: def.rarity,
                iconName: def.iconName
            )
            modelContext.insert(achievement)
        }
    }

    private func seedPowerUpsIfNeeded() {
        let descriptor = FetchDescriptor<PowerUp>()
        let count: Int
        do {
            count = try modelContext.fetchCount(descriptor)
        } catch {
            print("SparkDo [AppState]: Failed to count power-ups: \(error)")
            return
        }

        guard count == 0 else { return }

        // M3 fix: Use labeled struct fields instead of magic tuple indices
        for def in PowerUp.defaultPowerUps {
            let powerUp = PowerUp(
                name: def.name,
                description: def.description,
                category: def.category,
                sparkCost: def.sparkCost,
                colorHex: def.colorHex,
                iconName: def.iconName
            )
            modelContext.insert(powerUp)
        }
    }

    // MARK: - Today's Sparks

    var todaySparks: Int {
        sparkEngine.todaySparks()
    }

    // MARK: - Widget Sync

    func syncWidgetData() {
        let activeQuest = questSurfacing.fetchActiveQuests(sortedBy: .shuffle).first
        WidgetDataProvider.update(
            todaySparks: todaySparks,
            streakDays: streak.currentDays,
            flameStage: streak.flameStage,
            activeQuestTitle: activeQuest?.title,
            activeQuestXP: activeQuest?.xpValue ?? 0,
            activeQuestEnergy: activeQuest?.energyLevel ?? .medium
        )
    }
}
