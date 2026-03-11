import Foundation
import SwiftData

@Model
final class DailyChallenge {
    var id: UUID
    var title: String
    var descriptionText: String
    var targetCount: Int
    var currentCount: Int
    var bonusSparks: Int
    var date: Date
    var isCompleted: Bool

    init(
        title: String,
        description: String,
        targetCount: Int = 1,
        bonusSparks: Int = 75
    ) {
        self.id = UUID()
        self.title = title
        self.descriptionText = description
        self.targetCount = targetCount
        self.currentCount = 0
        self.bonusSparks = bonusSparks
        self.date = Date()
        self.isCompleted = false
    }

    var progress: Double {
        guard targetCount > 0 else { return 1.0 }
        return min(1.0, Double(currentCount) / Double(targetCount))
    }

    func incrementProgress() {
        guard currentCount < targetCount else { return }
        currentCount += 1
        if currentCount >= targetCount {
            isCompleted = true
        }
    }
}
