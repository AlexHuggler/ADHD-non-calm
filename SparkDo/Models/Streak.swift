import Foundation
import SwiftData

enum FlameStage: Int, Codable, Comparable {
    case ember = 0      // 0 days
    case spark = 1      // 1 day
    case flame = 2      // 3 days
    case blaze = 3      // 7 days
    case inferno = 4    // 14 days
    case supernova = 5  // 30 days

    static func < (lhs: FlameStage, rhs: FlameStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .ember: "Ember"
        case .spark: "Spark"
        case .flame: "Flame"
        case .blaze: "Blaze"
        case .inferno: "Inferno"
        case .supernova: "Supernova"
        }
    }

    var flameScale: CGFloat {
        switch self {
        case .ember: 0.3
        case .spark: 0.5
        case .flame: 0.7
        case .blaze: 0.85
        case .inferno: 1.0
        case .supernova: 1.2
        }
    }

    static func stage(for days: Int) -> FlameStage {
        switch days {
        case 0: .ember
        case 1...2: .spark
        case 3...6: .flame
        case 7...13: .blaze
        case 14...29: .inferno
        default: .supernova
        }
    }

    var demoted: FlameStage {
        FlameStage(rawValue: max(0, rawValue - 1)) ?? .ember
    }
}

@Model
final class Streak {
    var id: UUID
    var currentDays: Int
    var shieldDaysRemaining: Int
    var lastActiveDate: Date?
    var shieldsResetDate: Date?
    var longestStreak: Int

    init() {
        self.id = UUID()
        self.currentDays = 0
        self.shieldDaysRemaining = 2
        self.lastActiveDate = nil
        self.shieldsResetDate = nil
        self.longestStreak = 0
    }

    var flameStage: FlameStage {
        FlameStage.stage(for: currentDays)
    }
}
