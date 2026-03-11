import Foundation
import SwiftData

enum SparkSource: String, Codable {
    case questCompletion
    case sprintBonus
    case dailyChallenge
    case firstQuestBonus
    case hatTrickBonus
    case legendaryBonus
    case achievement
}

@Model
final class SparkTransaction {
    var id: UUID
    var amount: Int
    var source: SparkSource
    var questTitle: String
    var earnedAt: Date

    init(amount: Int, source: SparkSource, questTitle: String = "") {
        self.id = UUID()
        self.amount = amount
        self.source = source
        self.questTitle = questTitle
        self.earnedAt = Date()
    }
}
