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

    static let definitions: [(String, String, String, AchievementRarity, String)] = [
        ("first_spark", "First Spark", "Complete your first quest", .common, "bolt.fill"),
        ("sprint_champion", "Sprint Champion", "Complete 10 focus sprints", .rare, "timer"),
        ("early_bird", "Early Bird", "Complete a quest before 9 AM", .common, "sunrise.fill"),
        ("night_owl", "Night Owl", "Complete a quest after 10 PM", .common, "moon.fill"),
        ("consistency_king", "Consistency King", "Maintain a 7-day streak", .rare, "crown.fill"),
        ("quest_hoarder", "Quest Hoarder", "Capture 50 quests", .rare, "tray.full.fill"),
        ("spin_master", "Spin Master", "Use the wheel 25 times", .epic, "circle.dotted"),
        ("hyperfocus_hero", "Hyperfocus Hero", "Complete a 25-min sprint", .epic, "bolt.shield.fill"),
        ("hat_trick", "Hat Trick", "Complete 3 quests in a single day", .common, "hands.clap.fill"),
        ("legendary_day", "Legendary Day", "Complete 5 quests in a single day", .rare, "star.circle.fill"),
        ("centurion", "Centurion", "Earn 100 Sparks in a single day", .epic, "flame.circle.fill"),
        ("marathon", "Marathon Runner", "Complete a 30-day streak", .legendary, "figure.run"),
        ("speed_demon", "Speed Demon", "Complete 3 quests in under 30 minutes", .epic, "hare.fill"),
        ("zen_master", "Zen Master", "Complete 10 low-energy quests", .rare, "figure.mind.and.body"),
        ("level_10", "Double Digits", "Reach level 10", .legendary, "10.circle.fill"),
    ]
}
