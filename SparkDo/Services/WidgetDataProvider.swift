import WidgetKit

/// Bridges data between the main app and widget extensions via a shared App Group UserDefaults.
///
/// **Important:** Requires the `group.com.sparkdo.shared` App Group entitlement
/// to be configured in both the main app target and each widget extension target
/// in Xcode's Signing & Capabilities settings.
enum WidgetDataProvider {
    static let appGroupID = "group.com.sparkdo.shared"

    private enum Key {
        static let todaySparks = "widget.todaySparks"
        static let streakDays = "widget.streakDays"
        static let flameStageRaw = "widget.flameStageRaw"
        static let activeQuestTitle = "widget.activeQuestTitle"
        static let activeQuestXP = "widget.activeQuestXP"
        static let activeQuestEnergyRaw = "widget.activeQuestEnergyRaw"
    }

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Write (called from main app)

    static func update(
        todaySparks: Int,
        streakDays: Int,
        flameStage: FlameStage,
        activeQuestTitle: String?,
        activeQuestXP: Int,
        activeQuestEnergy: EnergyLevel
    ) {
        guard let defaults = sharedDefaults else {
            print("SparkDo [WidgetDataProvider]: App Group UserDefaults unavailable. Ensure entitlement is configured.")
            return
        }

        defaults.set(todaySparks, forKey: Key.todaySparks)
        defaults.set(streakDays, forKey: Key.streakDays)
        defaults.set(flameStage.rawValue, forKey: Key.flameStageRaw)
        defaults.set(activeQuestTitle, forKey: Key.activeQuestTitle)
        defaults.set(activeQuestXP, forKey: Key.activeQuestXP)
        defaults.set(activeQuestEnergy.rawValue, forKey: Key.activeQuestEnergyRaw)

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Read (called from widget extensions)

    static func readTodaySparks() -> Int {
        sharedDefaults?.integer(forKey: Key.todaySparks) ?? 0
    }

    static func readStreakDays() -> Int {
        sharedDefaults?.integer(forKey: Key.streakDays) ?? 0
    }

    static func readFlameStage() -> FlameStage {
        let raw = sharedDefaults?.integer(forKey: Key.flameStageRaw) ?? 0
        return FlameStage(rawValue: raw) ?? .ember
    }

    static func readActiveQuestTitle() -> String? {
        sharedDefaults?.string(forKey: Key.activeQuestTitle)
    }

    static func readActiveQuestXP() -> Int {
        sharedDefaults?.integer(forKey: Key.activeQuestXP) ?? 0
    }

    static func readActiveQuestEnergy() -> EnergyLevel {
        let raw = sharedDefaults?.string(forKey: Key.activeQuestEnergyRaw) ?? ""
        return EnergyLevel(rawValue: raw) ?? .medium
    }
}
