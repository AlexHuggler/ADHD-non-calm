import Foundation
import SwiftData

// M6 fix: @MainActor ensures all state mutations via ModelContext happen on Main Thread
@MainActor
@Observable
final class SparkEngine {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Quest Completion

    func completeQuest(_ quest: Quest, wasSprint: Bool = false, profile: PlayerProfile) -> [SparkTransaction] {
        guard quest.status == .active else { return [] }

        // H10 fix: Count quests completed today BEFORE marking this one complete,
        // then add 1 for deterministic bonus detection regardless of SwiftData auto-save timing.
        let previousTodayCount = questsCompletedToday()
        let todayCountIncludingThis = previousTodayCount + 1

        quest.status = .completed
        quest.completedAt = Date()
        profile.questsCompleted += 1

        var transactions: [SparkTransaction] = []

        // Base XP
        var baseAmount = quest.xpValue
        if wasSprint {
            baseAmount *= 2
        }

        let baseTx = SparkTransaction(
            amount: baseAmount,
            source: wasSprint ? .sprintBonus : .questCompletion,
            questTitle: quest.title
        )
        transactions.append(baseTx)

        // First quest of the day bonus
        if todayCountIncludingThis == 1 {
            let bonus = SparkTransaction(amount: 25, source: .firstQuestBonus, questTitle: "First Quest Bonus!")
            transactions.append(bonus)
        }

        // Hat Trick bonus (3 quests today)
        if todayCountIncludingThis == 3 {
            let bonus = SparkTransaction(amount: 50, source: .hatTrickBonus, questTitle: "Hat Trick!")
            transactions.append(bonus)
        }

        // Legendary bonus (5 quests today)
        if todayCountIncludingThis == 5 {
            let bonus = SparkTransaction(amount: 100, source: .legendaryBonus, questTitle: "Legendary!")
            transactions.append(bonus)
        }

        // Apply all transactions
        var totalEarned = 0
        for tx in transactions {
            modelContext.insert(tx)
            totalEarned += tx.amount
        }

        profile.totalSparks += totalEarned
        profile.spendableSparks += totalEarned

        let previousLevel = profile.level
        profile.recalculateLevel()

        if profile.level > previousLevel {
            // Level-up is handled by the caller for UI celebration
        }

        return transactions
    }

    // MARK: - Daily Challenge Completion

    func completeDailyChallenge(_ challenge: DailyChallenge, profile: PlayerProfile) -> SparkTransaction? {
        guard !challenge.isCompleted else { return nil }

        challenge.isCompleted = true
        let tx = SparkTransaction(
            amount: challenge.bonusSparks,
            source: .dailyChallenge,
            questTitle: challenge.title
        )
        modelContext.insert(tx)
        profile.totalSparks += tx.amount
        profile.spendableSparks += tx.amount
        profile.recalculateLevel()

        return tx
    }

    // MARK: - Spending

    func spendSparks(_ amount: Int, profile: PlayerProfile) -> Bool {
        guard profile.spendableSparks >= amount else { return false }
        profile.spendableSparks -= amount
        return true
    }

    // MARK: - Queries

    func todaySparks() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<SparkTransaction>(
            predicate: #Predicate { $0.earnedAt >= startOfDay }
        )
        // M1 fix: Log fetch errors instead of silent try?
        do {
            let transactions = try modelContext.fetch(descriptor)
            return transactions.reduce(0) { $0 + $1.amount }
        } catch {
            print("SparkDo [SparkEngine]: Failed to fetch today's sparks: \(error)")
            return 0
        }
    }

    func recentTransactions(limit: Int = 10) -> [SparkTransaction] {
        var descriptor = FetchDescriptor<SparkTransaction>(
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("SparkDo [SparkEngine]: Failed to fetch recent transactions: \(error)")
            return []
        }
    }

    // MARK: - Private Helpers

    private func questsCompletedToday() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        // C1 fix: Safe optional comparison instead of force unwrap in #Predicate
        let descriptor = FetchDescriptor<Quest>(
            predicate: #Predicate<Quest> { quest in
                quest.status == .completed && quest.completedAt ?? .distantPast >= startOfDay
            }
        )
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("SparkDo [SparkEngine]: Failed to count today's quests: \(error)")
            return 0
        }
    }
}
