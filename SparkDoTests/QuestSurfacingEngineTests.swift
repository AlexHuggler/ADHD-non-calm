import Testing
import SwiftData
@testable import SparkDo

@MainActor
struct QuestSurfacingEngineTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Quest.self, SparkTransaction.self, Streak.self,
            PowerUp.self, DailyChallenge.self, PlayerProfile.self,
            Achievement.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    // MARK: - fetchActiveQuests

    @Test func fetchActiveQuests_returnsOnlyActive() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let engine = QuestSurfacingEngine(modelContext: context)

        let active = Quest(title: "Active", xpValue: 10)
        let completed = Quest(title: "Completed", xpValue: 20)
        completed.status = .completed
        let skipped = Quest(title: "Skipped", xpValue: 15)
        skipped.status = .skipped

        context.insert(active)
        context.insert(completed)
        context.insert(skipped)

        let result = engine.fetchActiveQuests(sortedBy: .shuffle)

        #expect(result.count == 1)
        #expect(result[0].title == "Active")
    }

    @Test func fetchActiveQuests_quickestFirst() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let engine = QuestSurfacingEngine(modelContext: context)

        let slow = Quest(title: "Slow", xpValue: 10, estimatedMinutes: 30)
        let fast = Quest(title: "Fast", xpValue: 10, estimatedMinutes: 5)
        let medium = Quest(title: "Medium", xpValue: 10, estimatedMinutes: 15)

        context.insert(slow)
        context.insert(fast)
        context.insert(medium)

        let result = engine.fetchActiveQuests(sortedBy: .quickest)

        #expect(result[0].title == "Fast")
        #expect(result[1].title == "Medium")
        #expect(result[2].title == "Slow")
    }

    @Test func fetchActiveQuests_mostSparks() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let engine = QuestSurfacingEngine(modelContext: context)

        let low = Quest(title: "Low", xpValue: 10)
        let high = Quest(title: "High", xpValue: 75)
        let mid = Quest(title: "Mid", xpValue: 40)

        context.insert(low)
        context.insert(high)
        context.insert(mid)

        let result = engine.fetchActiveQuests(sortedBy: .mostSparks)

        #expect(result[0].title == "High")
        #expect(result[1].title == "Mid")
        #expect(result[2].title == "Low")
    }

    @Test func fetchActiveQuests_shuffleMode_returnsAll() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let engine = QuestSurfacingEngine(modelContext: context)

        for i in 1...5 {
            let q = Quest(title: "Quest \(i)", xpValue: 10)
            context.insert(q)
        }

        let result = engine.fetchActiveQuests(sortedBy: .shuffle)

        #expect(result.count == 5)
    }

    // MARK: - fetchQuestsForWheel

    @Test func fetchQuestsForWheel_limitsTo8() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let engine = QuestSurfacingEngine(modelContext: context)

        for i in 1...12 {
            let q = Quest(title: "Quest \(i)", xpValue: 10)
            context.insert(q)
        }

        let result = engine.fetchQuestsForWheel()

        #expect(result.count == 8)
    }

    @Test func fetchQuestsForWheel_fewerThan8_returnsAll() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let engine = QuestSurfacingEngine(modelContext: context)

        for i in 1...3 {
            let q = Quest(title: "Quest \(i)", xpValue: 10)
            context.insert(q)
        }

        let result = engine.fetchQuestsForWheel()

        #expect(result.count == 3)
    }

    // MARK: - recentlyCompleted

    @Test func recentlyCompleted_sortedByDate() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let engine = QuestSurfacingEngine(modelContext: context)

        let older = Quest(title: "Older", xpValue: 10)
        older.status = .completed
        older.completedAt = Date().addingTimeInterval(-7200)

        let newer = Quest(title: "Newer", xpValue: 20)
        newer.status = .completed
        newer.completedAt = Date().addingTimeInterval(-3600)

        context.insert(older)
        context.insert(newer)

        let result = engine.recentlyCompletedQuests()

        #expect(result.count == 2)
        #expect(result[0].title == "Newer")
        #expect(result[1].title == "Older")
    }

    // MARK: - questCount

    @Test func questCount_countsOnlyActive() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let engine = QuestSurfacingEngine(modelContext: context)

        let active1 = Quest(title: "A1", xpValue: 10)
        let active2 = Quest(title: "A2", xpValue: 20)
        let done = Quest(title: "Done", xpValue: 30)
        done.status = .completed

        context.insert(active1)
        context.insert(active2)
        context.insert(done)

        #expect(engine.questCount() == 2)
    }
}
