import Foundation
import SwiftData

// M6 fix: @MainActor ensures ModelContext access is Main Thread only
@MainActor
@Observable
final class QuestSurfacingEngine {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    enum SortMode: String, CaseIterable, Identifiable {
        case shuffle = "Shuffle"
        case quickest = "Quickest First"
        case mostSparks = "Most Sparks"

        var id: String { rawValue }
    }

    // M1 fix: Log fetch errors instead of silent try?
    func fetchActiveQuests(sortedBy mode: SortMode = .shuffle) -> [Quest] {
        let descriptor = FetchDescriptor<Quest>(
            predicate: #Predicate { $0.status == .active }
        )

        var quests: [Quest]
        do {
            quests = try modelContext.fetch(descriptor)
        } catch {
            print("SparkDo [QuestSurfacingEngine]: Failed to fetch active quests: \(error)")
            return []
        }

        switch mode {
        case .shuffle:
            quests.shuffle()
        case .quickest:
            quests.sort { $0.estimatedMinutes < $1.estimatedMinutes }
        case .mostSparks:
            quests.sort { $0.xpValue > $1.xpValue }
        }

        return quests
    }

    func fetchQuestsForWheel(maxSegments: Int = 8) -> [Quest] {
        var quests = fetchActiveQuests(sortedBy: .shuffle)

        // Limit to maxSegments for the wheel
        if quests.count > maxSegments {
            quests = Array(quests.prefix(maxSegments))
        }

        return quests
    }

    func recentlyCompletedQuests(limit: Int = 5) -> [Quest] {
        var descriptor = FetchDescriptor<Quest>(
            predicate: #Predicate { $0.status == .completed },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("SparkDo [QuestSurfacingEngine]: Failed to fetch completed quests: \(error)")
            return []
        }
    }

    func questCount() -> Int {
        let descriptor = FetchDescriptor<Quest>(
            predicate: #Predicate { $0.status == .active }
        )
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("SparkDo [QuestSurfacingEngine]: Failed to count active quests: \(error)")
            return 0
        }
    }
}
