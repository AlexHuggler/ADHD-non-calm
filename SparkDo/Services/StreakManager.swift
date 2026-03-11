import Foundation
import SwiftData

// M6 fix: @MainActor ensures ModelContext access is Main Thread only
@MainActor
@Observable
final class StreakManager {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getOrCreateStreak() -> Streak {
        let descriptor = FetchDescriptor<Streak>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let streak = Streak()
        modelContext.insert(streak)
        return streak
    }

    /// Call this when a quest is completed to update the streak.
    func recordActivity(streak: Streak) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Already active today — no change needed
        if let lastActive = streak.lastActiveDate,
           calendar.isDate(lastActive, inSameDayAs: today) {
            return
        }

        // Check for missed days
        if let lastActive = streak.lastActiveDate {
            let daysSinceLast = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastActive), to: today).day ?? 0

            if daysSinceLast > 1 {
                let missedDays = daysSinceLast - 1
                handleMissedDays(missedDays, streak: streak)
            }
        }

        // Regenerate shields on Monday
        regenerateShieldsIfNeeded(streak: streak)

        // Record today's activity
        streak.currentDays += 1
        streak.lastActiveDate = today
        streak.longestStreak = max(streak.longestStreak, streak.currentDays)
    }

    /// Check and apply missed day penalties (called on app launch).
    func checkForMissedDays(streak: Streak) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let lastActive = streak.lastActiveDate else { return }

        let daysSinceLast = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastActive), to: today).day ?? 0

        if daysSinceLast > 1 {
            let missedDays = daysSinceLast - 1
            handleMissedDays(missedDays, streak: streak)
        }

        regenerateShieldsIfNeeded(streak: streak)
    }

    // MARK: - Private

    private func handleMissedDays(_ count: Int, streak: Streak) {
        var remaining = count

        // Use shields first
        while remaining > 0 && streak.shieldDaysRemaining > 0 {
            streak.shieldDaysRemaining -= 1
            remaining -= 1
        }

        // For each unshielded missed day, shrink flame by one stage
        // But never reset to zero — shrink by stage, not to nothing
        if remaining > 0 {
            let currentStage = streak.flameStage
            let demotedStage = demoteStage(currentStage, times: remaining)
            streak.currentDays = daysForStage(demotedStage)
        }
    }

    private func demoteStage(_ stage: FlameStage, times: Int) -> FlameStage {
        var current = stage
        for _ in 0..<times {
            current = current.demoted
        }
        return current
    }

    private func daysForStage(_ stage: FlameStage) -> Int {
        switch stage {
        case .ember: 0
        case .spark: 1
        case .flame: 3
        case .blaze: 7
        case .inferno: 14
        case .supernova: 30
        }
    }

    private func regenerateShieldsIfNeeded(streak: Streak) {
        let calendar = Calendar.current
        let today = Date()

        // Regenerate shields on Monday
        if calendar.component(.weekday, from: today) == 2 { // Monday
            if let lastReset = streak.shieldsResetDate,
               calendar.isDate(lastReset, inSameDayAs: today) {
                return // Already reset this Monday
            }
            streak.shieldDaysRemaining = 2
            streak.shieldsResetDate = today
        }
    }
}
