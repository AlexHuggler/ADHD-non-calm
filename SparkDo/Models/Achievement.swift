import Foundation
import SwiftData

enum AchievementRarity: String, Codable, CaseIterable {
    case common
    case rare
    case epic
    case legendary

    var label: String {
        switch self {
        case .common: "Common"
        case .rare: "Rare"
        case .epic: "Epic"
        case .legendary: "Legendary"
        }
    }
}

@Model
final class Achievement {
    var id: UUID
    var key: String
    var name: String
    var descriptionText: String
    var rarity: AchievementRarity
    var iconName: String
    var isUnlocked: Bool
    var unlockedAt: Date?

    init(
        key: String,
        name: String,
        description: String,
        rarity: AchievementRarity,
        iconName: String
    ) {
        self.id = UUID()
        self.key = key
        self.name = name
        self.descriptionText = description
        self.rarity = rarity
        self.iconName = iconName
        self.isUnlocked = false
        self.unlockedAt = nil
    }

    func unlock() {
        guard !isUnlocked else { return }
        isUnlocked = true
        unlockedAt = Date()
    }

    // M3 fix: Use labeled struct instead of unlabeled tuple for type safety
    struct Definition {
        let key: String
        let name: String
        let description: String
        let rarity: AchievementRarity
        let iconName: String
    }

    static let definitions: [Definition] = [
        Definition(key: "first_spark", name: "First Spark", description: "Complete your first quest", rarity: .common, iconName: "bolt.fill"),
        Definition(key: "sprint_champion", name: "Sprint Champion", description: "Complete 10 focus sprints", rarity: .rare, iconName: "timer"),
        Definition(key: "early_bird", name: "Early Bird", description: "Complete a quest before 9 AM", rarity: .common, iconName: "sunrise.fill"),
        Definition(key: "night_owl", name: "Night Owl", description: "Complete a quest after 10 PM", rarity: .common, iconName: "moon.fill"),
        Definition(key: "consistency_king", name: "Consistency King", description: "Maintain a 7-day streak", rarity: .rare, iconName: "crown.fill"),
        Definition(key: "quest_hoarder", name: "Quest Hoarder", description: "Capture 50 quests", rarity: .rare, iconName: "tray.full.fill"),
        Definition(key: "spin_master", name: "Spin Master", description: "Use the wheel 25 times", rarity: .epic, iconName: "circle.dotted"),
        Definition(key: "hyperfocus_hero", name: "Hyperfocus Hero", description: "Complete a 25-min sprint", rarity: .epic, iconName: "bolt.shield.fill"),
        Definition(key: "hat_trick", name: "Hat Trick", description: "Complete 3 quests in a single day", rarity: .common, iconName: "hands.clap.fill"),
        Definition(key: "legendary_day", name: "Legendary Day", description: "Complete 5 quests in a single day", rarity: .rare, iconName: "star.circle.fill"),
        Definition(key: "centurion", name: "Centurion", description: "Earn 100 Sparks in a single day", rarity: .epic, iconName: "flame.circle.fill"),
        Definition(key: "marathon", name: "Marathon Runner", description: "Complete a 30-day streak", rarity: .legendary, iconName: "figure.run"),
        Definition(key: "speed_demon", name: "Speed Demon", description: "Complete 3 quests in under 30 minutes", rarity: .epic, iconName: "hare.fill"),
        Definition(key: "zen_master", name: "Zen Master", description: "Complete 10 low-energy quests", rarity: .rare, iconName: "figure.mind.and.body"),
        Definition(key: "level_10", name: "Double Digits", description: "Reach level 10", rarity: .legendary, iconName: "10.circle.fill"),
    ]
}
