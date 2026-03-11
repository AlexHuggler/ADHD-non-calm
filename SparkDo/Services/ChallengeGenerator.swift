import Foundation
import SwiftData

@Observable
final class ChallengeGenerator {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    struct ChallengeTemplate {
        let title: String
        let description: String
        let targetCount: Int
        let bonusSparks: Int
    }

    private let templates: [ChallengeTemplate] = [
        ChallengeTemplate(title: "Triple Threat", description: "Complete 3 quests today", targetCount: 3, bonusSparks: 75),
        ChallengeTemplate(title: "Quick Strike", description: "Complete a quest in under 10 minutes", targetCount: 1, bonusSparks: 50),
        ChallengeTemplate(title: "Face the Dragon", description: "Do one quest you've been avoiding", targetCount: 1, bonusSparks: 100),
        ChallengeTemplate(title: "Speed Run", description: "Complete 2 quests before lunch", targetCount: 2, bonusSparks: 75),
        ChallengeTemplate(title: "Energy Saver", description: "Complete 3 low-energy quests", targetCount: 3, bonusSparks: 60),
        ChallengeTemplate(title: "Sprint Star", description: "Complete a focus sprint", targetCount: 1, bonusSparks: 75),
        ChallengeTemplate(title: "XP Hunter", description: "Earn 100 Sparks today", targetCount: 1, bonusSparks: 50),
        ChallengeTemplate(title: "Morning Momentum", description: "Complete a quest before 10 AM", targetCount: 1, bonusSparks: 60),
        ChallengeTemplate(title: "Power Hour", description: "Complete 2 quests in one hour", targetCount: 2, bonusSparks: 80),
        ChallengeTemplate(title: "Chain Reaction", description: "Complete a quest chain", targetCount: 1, bonusSparks: 100),
        ChallengeTemplate(title: "The Big One", description: "Complete a quest worth 50+ XP", targetCount: 1, bonusSparks: 75),
        ChallengeTemplate(title: "Variety Pack", description: "Complete quests at 3 different energy levels", targetCount: 3, bonusSparks: 90),
        ChallengeTemplate(title: "Brain Dump", description: "Capture 5 new quests", targetCount: 5, bonusSparks: 50),
        ChallengeTemplate(title: "Wheel of Fortune", description: "Use the spin wheel and complete what it picks", targetCount: 1, bonusSparks: 75),
    ]

    func getTodaysChallenge() -> DailyChallenge {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        // Check for existing challenge today
        let descriptor = FetchDescriptor<DailyChallenge>(
            predicate: #Predicate { $0.date >= startOfDay }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        // Generate new challenge
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let templateIndex = dayOfYear % templates.count
        let template = templates[templateIndex]

        let challenge = DailyChallenge(
            title: template.title,
            description: template.description,
            targetCount: template.targetCount,
            bonusSparks: template.bonusSparks
        )

        modelContext.insert(challenge)
        return challenge
    }
}
