import Testing
import SwiftData
@testable import SparkDo

@MainActor
struct SparkEngineTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Quest.self, SparkTransaction.self, Streak.self,
            PowerUp.self, DailyChallenge.self, PlayerProfile.self,
            Achievement.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeEngine(_ container: ModelContainer) -> (SparkEngine, ModelContext) {
        let context = container.mainContext
        return (SparkEngine(modelContext: context), context)
    }

    // MARK: - Quest Completion

    @Test func completeQuest_baseSparks() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        context.insert(profile)

        let quest = Quest(title: "Test quest", xpValue: 30)
        context.insert(quest)

        let txs = engine.completeQuest(quest, profile: profile)

        #expect(quest.status == .completed)
        #expect(quest.completedAt != nil)
        #expect(profile.questsCompleted == 1)
        #expect(profile.totalSparks == 55) // 30 base + 25 first quest bonus
        #expect(profile.spendableSparks == 55)
        #expect(txs.count == 2) // base + first quest bonus
        #expect(txs[0].amount == 30)
        #expect(txs[0].source == .questCompletion)
    }

    @Test func completeQuest_inactiveQuest_returnsEmpty() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        context.insert(profile)

        let quest = Quest(title: "Done quest", xpValue: 20)
        quest.status = .completed
        context.insert(quest)

        let txs = engine.completeQuest(quest, profile: profile)

        #expect(txs.isEmpty)
        #expect(profile.totalSparks == 0)
    }

    @Test func completeQuest_sprintBonus_doublesXP() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        context.insert(profile)

        let quest = Quest(title: "Sprint quest", xpValue: 20)
        context.insert(quest)

        let txs = engine.completeQuest(quest, wasSprint: true, profile: profile)

        // First tx should be sprint bonus with doubled amount
        let baseTx = txs.first { $0.source == .sprintBonus }
        #expect(baseTx?.amount == 40) // 20 * 2
    }

    @Test func completeQuest_firstQuestBonus() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        context.insert(profile)

        let quest = Quest(title: "First today", xpValue: 10)
        context.insert(quest)

        let txs = engine.completeQuest(quest, profile: profile)

        let bonusTx = txs.first { $0.source == .firstQuestBonus }
        #expect(bonusTx != nil)
        #expect(bonusTx?.amount == 25)
    }

    @Test func completeQuest_secondQuest_noBonus() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        context.insert(profile)

        // Complete first quest
        let q1 = Quest(title: "First", xpValue: 10)
        context.insert(q1)
        _ = engine.completeQuest(q1, profile: profile)

        // Complete second quest
        let q2 = Quest(title: "Second", xpValue: 10)
        context.insert(q2)
        let txs = engine.completeQuest(q2, profile: profile)

        // Second quest should only have base tx, no milestone bonus
        let bonuses = txs.filter { $0.source != .questCompletion }
        #expect(bonuses.isEmpty)
    }

    @Test func completeQuest_hatTrickBonus() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        context.insert(profile)

        // Complete 2 quests first
        for i in 1...2 {
            let q = Quest(title: "Quest \(i)", xpValue: 10)
            context.insert(q)
            _ = engine.completeQuest(q, profile: profile)
        }

        // Third quest should trigger hat trick
        let q3 = Quest(title: "Third", xpValue: 10)
        context.insert(q3)
        let txs = engine.completeQuest(q3, profile: profile)

        let hatTrick = txs.first { $0.source == .hatTrickBonus }
        #expect(hatTrick != nil)
        #expect(hatTrick?.amount == 50)
    }

    @Test func completeQuest_legendaryBonus() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        context.insert(profile)

        // Complete 4 quests first
        for i in 1...4 {
            let q = Quest(title: "Quest \(i)", xpValue: 10)
            context.insert(q)
            _ = engine.completeQuest(q, profile: profile)
        }

        // Fifth quest should trigger legendary
        let q5 = Quest(title: "Fifth", xpValue: 10)
        context.insert(q5)
        let txs = engine.completeQuest(q5, profile: profile)

        let legendary = txs.first { $0.source == .legendaryBonus }
        #expect(legendary != nil)
        #expect(legendary?.amount == 100)
    }

    @Test func completeQuest_updatesProfileCounters() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        profile.questsCompleted = 5
        profile.totalSparks = 100
        profile.spendableSparks = 50
        context.insert(profile)

        let quest = Quest(title: "Counter test", xpValue: 40)
        context.insert(quest)
        _ = engine.completeQuest(quest, profile: profile)

        #expect(profile.questsCompleted == 6)
        // 40 base + 25 first quest bonus = 65
        #expect(profile.totalSparks == 165)
        #expect(profile.spendableSparks == 115)
    }

    @Test func completeQuest_triggersLevelRecalculation() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        // Level 2 requires 100 sparks. Set to 90 so completing a quest pushes past.
        profile.totalSparks = 90
        profile.spendableSparks = 90
        profile.level = 1
        context.insert(profile)

        let quest = Quest(title: "Level up", xpValue: 20)
        context.insert(quest)
        _ = engine.completeQuest(quest, profile: profile)

        // 90 + 20 base + 25 first quest = 135 → level 2 (requires 100)
        #expect(profile.level >= 2)
    }

    // MARK: - Undo

    @Test func undoCompletion_refundsSparks() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        context.insert(profile)

        let quest = Quest(title: "Undo me", xpValue: 30)
        context.insert(quest)

        let txs = engine.completeQuest(quest, profile: profile)
        let sparksAfterComplete = profile.totalSparks

        engine.undoQuestCompletion(quest, transactions: txs, profile: profile)

        #expect(quest.status == .active)
        #expect(quest.completedAt == nil)
        #expect(profile.questsCompleted == 0)
        #expect(profile.totalSparks == sparksAfterComplete - txs.reduce(0) { $0 + $1.amount })
    }

    @Test func undoCompletion_neverGoesNegative() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        context.insert(profile)

        let quest = Quest(title: "Undo negative", xpValue: 50)
        context.insert(quest)

        let txs = engine.completeQuest(quest, profile: profile)

        // Spend most sparks first
        profile.spendableSparks = 5
        profile.totalSparks = 5

        engine.undoQuestCompletion(quest, transactions: txs, profile: profile)

        #expect(profile.totalSparks == 0)
        #expect(profile.spendableSparks == 0)
    }

    // MARK: - Daily Challenge

    @Test func completeDailyChallenge_earnsBonusSparks() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        context.insert(profile)

        let challenge = DailyChallenge(title: "Test", description: "Do it", targetCount: 1, bonusSparks: 75)
        context.insert(challenge)

        let tx = engine.completeDailyChallenge(challenge, profile: profile)

        #expect(tx != nil)
        #expect(tx?.amount == 75)
        #expect(tx?.source == .dailyChallenge)
        #expect(challenge.isCompleted)
        #expect(profile.totalSparks == 75)
    }

    @Test func completeDailyChallenge_alreadyCompleted_returnsNil() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        context.insert(profile)

        let challenge = DailyChallenge(title: "Done", description: "Already done", targetCount: 1, bonusSparks: 75)
        challenge.isCompleted = true
        context.insert(challenge)

        let tx = engine.completeDailyChallenge(challenge, profile: profile)

        #expect(tx == nil)
        #expect(profile.totalSparks == 0)
    }

    // MARK: - Spending

    @Test func spendSparks_sufficientAndInsufficient() throws {
        let container = try makeContainer()
        let (engine, context) = makeEngine(container)

        let profile = PlayerProfile()
        profile.spendableSparks = 100
        context.insert(profile)

        #expect(engine.spendSparks(50, profile: profile) == true)
        #expect(profile.spendableSparks == 50)

        #expect(engine.spendSparks(51, profile: profile) == false)
        #expect(profile.spendableSparks == 50) // unchanged
    }
}
