import SwiftData
import SwiftUI

@MainActor
enum PreviewSampleData {
    static var container: ModelContainer {
        let schema = Schema([
            Quest.self,
            SparkTransaction.self,
            Streak.self,
            PowerUp.self,
            DailyChallenge.self,
            PlayerProfile.self,
            Achievement.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        seedData(in: container.mainContext)
        return container
    }

    static func seedData(in context: ModelContext) {
        // Profile
        let profile = PlayerProfile()
        profile.totalSparks = 1250
        profile.spendableSparks = 480
        profile.level = 5
        profile.questsCompleted = 37
        profile.sprintsCompleted = 12
        profile.totalFocusMinutes = 180
        context.insert(profile)

        // Streak
        let streak = Streak()
        streak.currentDays = 7
        streak.longestStreak = 14
        streak.shieldDaysRemaining = 1
        streak.lastActiveDate = Date()
        context.insert(streak)

        // Daily challenge
        let challenge = DailyChallenge(
            title: "Complete 3 quests",
            description: "Finish any 3 quests today for bonus sparks",
            targetCount: 3,
            bonusSparks: 75
        )
        challenge.currentCount = 1
        context.insert(challenge)

        // Active quests
        let quests = [
            Quest(title: "Review pull request", xpValue: 25, energyLevel: .low, estimatedMinutes: 10),
            Quest(title: "Write unit tests for auth module", xpValue: 50, energyLevel: .high, estimatedMinutes: 30),
            Quest(title: "Update project README", xpValue: 15, energyLevel: .low, estimatedMinutes: 5),
            Quest(title: "Fix navigation bug on iPad", xpValue: 75, energyLevel: .medium, estimatedMinutes: 25, isEpic: true, epicMotivation: "Ship the iPad release!"),
            Quest(title: "Refactor settings view", xpValue: 40, energyLevel: .medium, estimatedMinutes: 20),
        ]
        for quest in quests {
            context.insert(quest)
        }

        // Completed quest for recent wins
        let completedQuest = Quest(title: "Set up CI pipeline", xpValue: 60, energyLevel: .high, estimatedMinutes: 45)
        completedQuest.status = .completed
        completedQuest.completedAt = Date().addingTimeInterval(-3600)
        context.insert(completedQuest)

        // Spark transactions
        let tx1 = SparkTransaction(amount: 25, source: .questCompletion, questTitle: "Set up CI pipeline")
        let tx2 = SparkTransaction(amount: 25, source: .firstQuestBonus, questTitle: "First Quest Bonus!")
        context.insert(tx1)
        context.insert(tx2)

        // Achievements (seed a few)
        let firstSpark = Achievement(key: "first_spark", name: "First Spark", description: "Complete your first quest", rarity: .common, iconName: "bolt.fill")
        firstSpark.unlock()
        context.insert(firstSpark)

        let hatTrick = Achievement(key: "hat_trick", name: "Hat Trick", description: "Complete 3 quests in a single day", rarity: .common, iconName: "hands.clap.fill")
        hatTrick.unlock()
        context.insert(hatTrick)

        let sprintChamp = Achievement(key: "sprint_champion", name: "Sprint Champion", description: "Complete 10 focus sprints", rarity: .rare, iconName: "timer")
        context.insert(sprintChamp)

        let marathon = Achievement(key: "marathon", name: "Marathon Runner", description: "Complete a 30-day streak", rarity: .legendary, iconName: "figure.run")
        context.insert(marathon)

        // Power-ups
        let powerUp1 = PowerUp(name: "Midnight Galaxy", description: "Deep space purple theme", category: .theme, sparkCost: 200, colorHex: "#2D1B69", iconName: "moon.stars.fill")
        let powerUp2 = PowerUp(name: "Neon Coral", description: "Coral pink card accent", category: .cardColor, sparkCost: 100, colorHex: "#FF6B6B", iconName: "paintbrush.fill")
        powerUp2.isPurchased = true
        context.insert(powerUp1)
        context.insert(powerUp2)
    }

    // Convenience accessors for previews that need explicit model objects
    static var sampleProfile: PlayerProfile {
        let p = PlayerProfile()
        p.totalSparks = 1250
        p.spendableSparks = 480
        p.level = 5
        p.questsCompleted = 37
        p.sprintsCompleted = 12
        p.totalFocusMinutes = 180
        return p
    }

    static var sampleStreak: Streak {
        let s = Streak()
        s.currentDays = 7
        s.longestStreak = 14
        s.shieldDaysRemaining = 1
        return s
    }

    static var sampleChallenge: DailyChallenge {
        let c = DailyChallenge(
            title: "Complete 3 quests",
            description: "Finish any 3 quests today for bonus sparks",
            targetCount: 3,
            bonusSparks: 75
        )
        c.currentCount = 1
        return c
    }

    static var sampleQuest: Quest {
        Quest(title: "Fix navigation bug on iPad", xpValue: 75, energyLevel: .medium, estimatedMinutes: 25, isEpic: true, epicMotivation: "Ship the iPad release!")
    }

    static var sampleQuests: [Quest] {
        [
            Quest(title: "Review pull request", xpValue: 25, energyLevel: .low, estimatedMinutes: 10),
            Quest(title: "Write unit tests", xpValue: 50, energyLevel: .high, estimatedMinutes: 30),
            Quest(title: "Update README", xpValue: 15, energyLevel: .low, estimatedMinutes: 5),
            Quest(title: "Fix iPad nav bug", xpValue: 75, energyLevel: .medium, estimatedMinutes: 25),
            Quest(title: "Refactor settings", xpValue: 40, energyLevel: .medium, estimatedMinutes: 20),
        ]
    }
}
