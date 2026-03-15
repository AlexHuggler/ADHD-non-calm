import Testing
import SwiftData
@testable import SparkDo

@MainActor
struct StreakManagerTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Quest.self, SparkTransaction.self, Streak.self,
            PowerUp.self, DailyChallenge.self, PlayerProfile.self,
            Achievement.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - getOrCreateStreak

    @Test func getOrCreateStreak_createsNew() throws {
        let container = try makeContainer()
        let manager = StreakManager(modelContext: container.mainContext)

        let streak = manager.getOrCreateStreak()

        #expect(streak.currentDays == 0)
        #expect(streak.shieldDaysRemaining == 2)
        #expect(streak.lastActiveDate == nil)
    }

    @Test func getOrCreateStreak_returnsExisting() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let manager = StreakManager(modelContext: context)

        let existing = Streak()
        existing.currentDays = 5
        context.insert(existing)

        let fetched = manager.getOrCreateStreak()

        #expect(fetched.currentDays == 5)
    }

    // MARK: - recordActivity

    @Test func recordActivity_firstEver() throws {
        let container = try makeContainer()
        let manager = StreakManager(modelContext: container.mainContext)

        let streak = Streak()
        container.mainContext.insert(streak)

        manager.recordActivity(streak: streak)

        #expect(streak.currentDays == 1)
        #expect(streak.lastActiveDate != nil)
        #expect(streak.longestStreak == 1)
    }

    @Test func recordActivity_sameDay_noChange() throws {
        let container = try makeContainer()
        let manager = StreakManager(modelContext: container.mainContext)

        let streak = Streak()
        streak.currentDays = 3
        streak.lastActiveDate = Calendar.current.startOfDay(for: Date())
        container.mainContext.insert(streak)

        manager.recordActivity(streak: streak)

        #expect(streak.currentDays == 3) // unchanged
    }

    @Test func recordActivity_consecutiveDay() throws {
        let container = try makeContainer()
        let manager = StreakManager(modelContext: container.mainContext)

        let streak = Streak()
        streak.currentDays = 5
        streak.lastActiveDate = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))
        container.mainContext.insert(streak)

        manager.recordActivity(streak: streak)

        #expect(streak.currentDays == 6)
        #expect(streak.longestStreak == 6)
    }

    @Test func recordActivity_missedOneDay_withShield() throws {
        let container = try makeContainer()
        let manager = StreakManager(modelContext: container.mainContext)

        let streak = Streak()
        streak.currentDays = 7
        streak.shieldDaysRemaining = 2
        // Last active 2 days ago → 1 missed day
        streak.lastActiveDate = Calendar.current.date(byAdding: .day, value: -2, to: Calendar.current.startOfDay(for: Date()))
        container.mainContext.insert(streak)

        manager.recordActivity(streak: streak)

        // Shield consumed, streak preserved, then incremented
        #expect(streak.shieldDaysRemaining == 1)
        #expect(streak.currentDays == 8) // 7 preserved + 1 for today
    }

    @Test func recordActivity_missedOneDay_noShield() throws {
        let container = try makeContainer()
        let manager = StreakManager(modelContext: container.mainContext)

        let streak = Streak()
        streak.currentDays = 7 // blaze stage
        streak.shieldDaysRemaining = 0
        // Last active 2 days ago → 1 missed day
        streak.lastActiveDate = Calendar.current.date(byAdding: .day, value: -2, to: Calendar.current.startOfDay(for: Date()))
        container.mainContext.insert(streak)

        manager.recordActivity(streak: streak)

        // Demoted one stage from blaze(7) → flame(3), then +1 for today
        #expect(streak.currentDays == 4) // daysForStage(.flame) = 3, +1 for today
    }

    @Test func recordActivity_missedMultipleDays() throws {
        let container = try makeContainer()
        let manager = StreakManager(modelContext: container.mainContext)

        let streak = Streak()
        streak.currentDays = 14 // inferno stage
        streak.shieldDaysRemaining = 1
        // Last active 4 days ago → 3 missed days
        streak.lastActiveDate = Calendar.current.date(byAdding: .day, value: -4, to: Calendar.current.startOfDay(for: Date()))
        container.mainContext.insert(streak)

        manager.recordActivity(streak: streak)

        // 3 missed days: 1 shield consumed, 2 demotions remaining
        // inferno → blaze → flame (2 demotions)
        // daysForStage(.flame) = 3, +1 for today = 4
        #expect(streak.shieldDaysRemaining == 0)
        #expect(streak.currentDays == 4)
    }

    // MARK: - checkForMissedDays

    @Test func checkForMissedDays_applyPenalty() throws {
        let container = try makeContainer()
        let manager = StreakManager(modelContext: container.mainContext)

        let streak = Streak()
        streak.currentDays = 7 // blaze
        streak.shieldDaysRemaining = 0
        streak.lastActiveDate = Calendar.current.date(byAdding: .day, value: -3, to: Calendar.current.startOfDay(for: Date()))
        container.mainContext.insert(streak)

        manager.checkForMissedDays(streak: streak)

        // 2 missed days, 0 shields → 2 demotions: blaze → flame → spark
        // daysForStage(.spark) = 1
        #expect(streak.currentDays == 1)
    }

    // MARK: - Demotion stages

    @Test func demotionStages_correctMapping() throws {
        // Test FlameStage.demoted directly
        #expect(FlameStage.ember.demoted == .ember)
        #expect(FlameStage.spark.demoted == .ember)
        #expect(FlameStage.flame.demoted == .spark)
        #expect(FlameStage.blaze.demoted == .flame)
        #expect(FlameStage.inferno.demoted == .blaze)
        #expect(FlameStage.supernova.demoted == .inferno)
    }
}
