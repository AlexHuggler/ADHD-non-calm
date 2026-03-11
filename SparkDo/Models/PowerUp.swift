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

    // M3 fix: Use labeled struct instead of unlabeled tuple for type safety
    struct Definition {
        let name: String
        let description: String
        let category: PowerUpCategory
        let sparkCost: Int
        let colorHex: String?
        let iconName: String
    }

    static let defaultPowerUps: [Definition] = [
        Definition(name: "Midnight Galaxy", description: "Deep space purple theme", category: .theme, sparkCost: 200, colorHex: "#2D1B69", iconName: "moon.stars.fill"),
        Definition(name: "Sunset Blaze", description: "Warm orange gradient theme", category: .theme, sparkCost: 200, colorHex: "#FF6B35", iconName: "sun.horizon.fill"),
        Definition(name: "Ocean Depths", description: "Cool deep blue theme", category: .theme, sparkCost: 200, colorHex: "#1B4B7A", iconName: "water.waves"),
        Definition(name: "Neon Coral", description: "Coral pink card accent", category: .cardColor, sparkCost: 100, colorHex: "#FF6B6B", iconName: "paintbrush.fill"),
        Definition(name: "Electric Mint", description: "Mint green card accent", category: .cardColor, sparkCost: 100, colorHex: "#5CD859", iconName: "leaf.fill"),
        Definition(name: "Gold Rush", description: "Golden card accent", category: .cardColor, sparkCost: 100, colorHex: "#FECA57", iconName: "star.fill"),
        Definition(name: "Speed Demon", description: "Complete 5 quests in one day", category: .badge, sparkCost: 150, colorHex: nil, iconName: "flame.fill"),
        Definition(name: "Zen Master", description: "Complete 10 low-energy quests", category: .badge, sparkCost: 150, colorHex: nil, iconName: "figure.mind.and.body"),
        Definition(name: "Victory Fanfare", description: "Epic completion sound", category: .sound, sparkCost: 75, colorHex: nil, iconName: "speaker.wave.3.fill"),
        Definition(name: "Pixel Chime", description: "Retro 8-bit sound", category: .sound, sparkCost: 75, colorHex: nil, iconName: "arcade.stick"),
    ]
}
