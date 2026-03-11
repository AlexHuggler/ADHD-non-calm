import Foundation
import SwiftData

@Model
final class PlayerProfile {
    var id: UUID
    var totalSparks: Int
    var spendableSparks: Int
    var level: Int
    var questsCompleted: Int
    var sprintsCompleted: Int
    var totalFocusMinutes: Int
    var joinDate: Date
    var isPremium: Bool
    var dailySprintsUsed: Int
    var lastSprintResetDate: Date?
    var soundEnabled: Bool
    var hapticsEnabled: Bool

    init() {
        self.id = UUID()
        self.totalSparks = 0
        self.spendableSparks = 0
        self.level = 1
        self.questsCompleted = 0
        self.sprintsCompleted = 0
        self.totalFocusMinutes = 0
        self.joinDate = Date()
        self.isPremium = false
        self.dailySprintsUsed = 0
        self.lastSprintResetDate = nil
        self.soundEnabled = true
        self.hapticsEnabled = true
    }

    /// Level N requires N*(N-1)*50 cumulative sparks
    static func sparksRequired(forLevel level: Int) -> Int {
        level * (level - 1) * 50
    }

    var sparksForCurrentLevel: Int {
        Self.sparksRequired(forLevel: level)
    }

    var sparksForNextLevel: Int {
        Self.sparksRequired(forLevel: level + 1)
    }

    var levelProgress: Double {
        let current = totalSparks - sparksForCurrentLevel
        let needed = sparksForNextLevel - sparksForCurrentLevel
        guard needed > 0 else { return 0 }
        return min(1.0, Double(current) / Double(needed))
    }

    func recalculateLevel() {
        var newLevel = 1
        while Self.sparksRequired(forLevel: newLevel + 1) <= totalSparks {
            newLevel += 1
        }
        level = newLevel
    }

    var canUseSprint: Bool {
        isPremium || dailySprintsUsed < 1
    }

    func resetDailySprintsIfNeeded() {
        let calendar = Calendar.current
        if let lastReset = lastSprintResetDate,
           !calendar.isDateInToday(lastReset) {
            dailySprintsUsed = 0
            lastSprintResetDate = Date()
        } else if lastSprintResetDate == nil {
            lastSprintResetDate = Date()
        }
    }
}
