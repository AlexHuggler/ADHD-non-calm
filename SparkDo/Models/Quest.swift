import Foundation
import SwiftData

enum EnergyLevel: String, Codable, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: "Low Energy"
        case .medium: "Medium Energy"
        case .high: "High Energy"
        }
    }

    var emoji: String {
        switch self {
        case .low: "🟢"
        case .medium: "🟠"
        case .high: "🔴"
        }
    }
}

enum QuestStatus: String, Codable {
    case active
    case completed
    case skipped
}

@Model
final class Quest {
    var id: UUID
    var title: String
    var xpValue: Int
    var energyLevel: EnergyLevel
    var estimatedMinutes: Int
    var notes: String
    var status: QuestStatus
    var isEpic: Bool
    var epicMotivation: String
    var createdAt: Date
    var completedAt: Date?
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \Quest.parentQuest)
    var childQuests: [Quest]?

    @Relationship
    var parentQuest: Quest?

    init(
        title: String,
        xpValue: Int = 25,
        energyLevel: EnergyLevel = .medium,
        estimatedMinutes: Int = 15,
        notes: String = "",
        isEpic: Bool = false,
        epicMotivation: String = "",
        parentQuest: Quest? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.xpValue = xpValue
        self.energyLevel = energyLevel
        self.estimatedMinutes = estimatedMinutes
        self.notes = notes
        self.status = .active
        self.isEpic = isEpic
        self.epicMotivation = epicMotivation
        self.createdAt = Date()
        self.completedAt = nil
        self.sortOrder = 0
        self.parentQuest = parentQuest
    }

    var isCompleted: Bool { status == .completed }
    var isActive: Bool { status == .active }

    var chainChildren: [Quest] {
        (childQuests ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    static func autoXP(for title: String) -> Int {
        let wordCount = title.split(separator: " ").count
        if wordCount < 5 { return 10 }
        if wordCount <= 15 { return 25 }
        return 50
    }
}
