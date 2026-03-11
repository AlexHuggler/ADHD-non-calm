import Foundation
import SwiftData
import SwiftUI

enum PowerUpCategory: String, Codable, CaseIterable {
    case theme
    case cardColor
    case badge
    case sound

    var label: String {
        switch self {
        case .theme: "Themes"
        case .cardColor: "Card Colors"
        case .badge: "Badges"
        case .sound: "Sounds"
        }
    }
}

@Model
final class PowerUp {
    var id: UUID
    var name: String
    var descriptionText: String
    var category: PowerUpCategory
    var sparkCost: Int
    var isPurchased: Bool
    var isEquipped: Bool
    var colorHex: String?
    var iconName: String

    init(
        name: String,
        description: String,
        category: PowerUpCategory,
        sparkCost: Int,
        colorHex: String? = nil,
        iconName: String = "sparkles"
    ) {
        self.id = UUID()
        self.name = name
        self.descriptionText = description
        self.category = category
        self.sparkCost = sparkCost
        self.isPurchased = false
        self.isEquipped = false
        self.colorHex = colorHex
        self.iconName = iconName
    }

    static let defaultPowerUps: [(String, String, PowerUpCategory, Int, String?, String)] = [
        ("Midnight Galaxy", "Deep space purple theme", .theme, 200, "#2D1B69", "moon.stars.fill"),
        ("Sunset Blaze", "Warm orange gradient theme", .theme, 200, "#FF6B35", "sun.horizon.fill"),
        ("Ocean Depths", "Cool deep blue theme", .theme, 200, "#1B4B7A", "water.waves"),
        ("Neon Coral", "Coral pink card accent", .cardColor, 100, "#FF6B6B", "paintbrush.fill"),
        ("Electric Mint", "Mint green card accent", .cardColor, 100, "#5CD859", "leaf.fill"),
        ("Gold Rush", "Golden card accent", .cardColor, 100, "#FECA57", "star.fill"),
        ("Speed Demon", "Complete 5 quests in one day", .badge, 150, nil, "flame.fill"),
        ("Zen Master", "Complete 10 low-energy quests", .badge, 150, nil, "figure.mind.and.body"),
        ("Victory Fanfare", "Epic completion sound", .sound, 75, nil, "speaker.wave.3.fill"),
        ("Pixel Chime", "Retro 8-bit sound", .sound, 75, nil, "arcade.stick"),
    ]
}
