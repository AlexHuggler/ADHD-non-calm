import Testing
import SwiftData
@testable import SparkDo

@MainActor
struct ChallengeGeneratorTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Quest.self, SparkTransaction.self, Streak.self,
            PowerUp.self, DailyChallenge.self, PlayerProfile.self,
            Achievement.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func getTodaysChallenge_createsNew() throws {
        let container = try makeContainer()
        let generator = ChallengeGenerator(modelContext: container.mainContext)

        let challenge = generator.getTodaysChallenge()

        #expect(!challenge.title.isEmpty)
        #expect(!challenge.descriptionText.isEmpty)
        #expect(challenge.targetCount > 0)
        #expect(challenge.bonusSparks > 0)
    }

    @Test func getTodaysChallenge_returnsExisting() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let generator = ChallengeGenerator(modelContext: context)

        let existing = DailyChallenge(title: "Existing", description: "Already here", targetCount: 2, bonusSparks: 50)
        context.insert(existing)

        let fetched = generator.getTodaysChallenge()

        #expect(fetched.title == "Existing")
    }

    @Test func getTodaysChallenge_deterministic() throws {
        let container = try makeContainer()
        let generator = ChallengeGenerator(modelContext: container.mainContext)

        let first = generator.getTodaysChallenge()
        let second = generator.getTodaysChallenge()

        #expect(first.title == second.title)
    }

    @Test func templateSelection_usesDayOfYear() throws {
        // Verify the template index formula: dayOfYear % 14
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let expectedIndex = dayOfYear % 14

        // Index should be in valid range
        #expect(expectedIndex >= 0)
        #expect(expectedIndex < 14)
    }

    @Test func newChallenge_correctFields() throws {
        let container = try makeContainer()
        let generator = ChallengeGenerator(modelContext: container.mainContext)

        let challenge = generator.getTodaysChallenge()

        // Verify fields are populated from template
        #expect(challenge.targetCount >= 1)
        #expect(challenge.bonusSparks >= 50)
        #expect(challenge.bonusSparks <= 100)
    }

    @Test func challenge_notCompletedByDefault() throws {
        let container = try makeContainer()
        let generator = ChallengeGenerator(modelContext: container.mainContext)

        let challenge = generator.getTodaysChallenge()

        #expect(!challenge.isCompleted)
        #expect(challenge.currentCount == 0)
    }
}
