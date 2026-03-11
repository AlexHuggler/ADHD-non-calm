import Foundation
import SwiftData

@Observable
final class SparkEngine {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Quest Completion

    func completeQuest(_ quest: Quest, wasSprint: Bool = false, profile: PlayerProfile) -> [SparkTransaction] {
        guard quest.status == .active else { return [] }

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
        if isFirstQuestToday(profile: profile) {
            let bonus = SparkTransaction(amount: 25, source: .firstQuestBonus, questTitle: "First Quest Bonus!")
            transactions.append(bonus)
        }

        // Hat Trick bonus (3 quests today)
        let todayCount = questsCompletedToday()
        if todayCount == 3 {
            let bonus = SparkTransaction(amount: 50, source: .hatTrickBonus, questTitle: "Hat Trick!")
            transactions.append(bonus)
        }

        // Legendary bonus (5 quests today)
        if todayCount == 5 {
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
        let didLevelUp = profile.level > previousLevel

        if didLevelUp {
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
        let transactions = (try? modelContext.fetch(descriptor)) ?? []
        return transactions.reduce(0) { $0 + $1.amount }
    }

    func recentTransactions(limit: Int = 10) -> [SparkTransaction] {
        var descriptor = FetchDescriptor<SparkTransaction>(
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Private Helpers

    private func isFirstQuestToday(profile: PlayerProfile) -> Bool {
        questsCompletedToday() == 1
    }

    private func questsCompletedToday() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<Quest>(
            predicate: #Predicate { quest in
                quest.status == .completed && quest.completedAt != nil && quest.completedAt! >= startOfDay
            }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
