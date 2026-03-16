import Testing
@testable import SparkDo

struct ModelTests {

    // MARK: - PlayerProfile.sparksRequired

    @Test func sparksRequired_level1_is0() {
        #expect(PlayerProfile.sparksRequired(forLevel: 1) == 0)
    }

    @Test func sparksRequired_level2_is100() {
        #expect(PlayerProfile.sparksRequired(forLevel: 2) == 100)
    }

    @Test func sparksRequired_level5_is1000() {
        #expect(PlayerProfile.sparksRequired(forLevel: 5) == 1000)
    }

    @Test func sparksRequired_invalidLevel_is0() {
        #expect(PlayerProfile.sparksRequired(forLevel: 0) == 0)
        #expect(PlayerProfile.sparksRequired(forLevel: -1) == 0)
    }

    // MARK: - PlayerProfile.levelProgress

    @Test func levelProgress_midway() {
        let profile = PlayerProfile()
        profile.level = 2
        // Level 2 requires 100, level 3 requires 300. Midway = 200
        profile.totalSparks = 200
        #expect(profile.levelProgress == 0.5)
    }

    @Test func levelProgress_atCurrentLevel_is0() {
        let profile = PlayerProfile()
        profile.level = 2
        profile.totalSparks = 100 // exactly at level 2 threshold
        #expect(profile.levelProgress == 0.0)
    }

    @Test func levelProgress_cappedAt1() {
        let profile = PlayerProfile()
        profile.level = 2
        profile.totalSparks = 500 // well beyond level 3
        #expect(profile.levelProgress == 1.0)
    }

    // MARK: - PlayerProfile.recalculateLevel

    @Test func recalculateLevel_correctLevel() {
        let profile = PlayerProfile()
        // Level 3 requires 300 sparks (3*2*50)
        // Level 4 requires 600 sparks (4*3*50)
        profile.totalSparks = 350
        profile.recalculateLevel()
        #expect(profile.level == 3)

        profile.totalSparks = 600
        profile.recalculateLevel()
        #expect(profile.level == 4)

        profile.totalSparks = 0
        profile.recalculateLevel()
        #expect(profile.level == 1)
    }

    // MARK: - Quest.autoXP

    @Test func questAutoXP_shortTitle() {
        // < 5 words → 10
        #expect(Quest.autoXP(for: "Fix bug") == 10)
        #expect(Quest.autoXP(for: "Do it now fast") == 10)
    }

    @Test func questAutoXP_mediumTitle() {
        // 5-15 words → 25
        #expect(Quest.autoXP(for: "Write unit tests for the auth module") == 25)
    }

    @Test func questAutoXP_longTitle() {
        // > 15 words → 50
        let long = "This is a very long quest title that has way more than fifteen words in it to test the high XP tier"
        #expect(Quest.autoXP(for: long) == 50)
    }

    // MARK: - DailyChallenge.progress

    @Test func dailyChallengeProgress_calculation() {
        let challenge = DailyChallenge(title: "Test", description: "Test", targetCount: 4, bonusSparks: 50)

        #expect(challenge.progress == 0.0)

        challenge.currentCount = 2
        #expect(challenge.progress == 0.5)

        challenge.currentCount = 4
        #expect(challenge.progress == 1.0)

        challenge.currentCount = 10 // over target, capped
        #expect(challenge.progress == 1.0)
    }

    // MARK: - FlameStage

    @Test func flameStage_stageForDays() {
        #expect(FlameStage.stage(for: 0) == .ember)
        #expect(FlameStage.stage(for: 1) == .spark)
        #expect(FlameStage.stage(for: 2) == .spark)
        #expect(FlameStage.stage(for: 3) == .flame)
        #expect(FlameStage.stage(for: 6) == .flame)
        #expect(FlameStage.stage(for: 7) == .blaze)
        #expect(FlameStage.stage(for: 13) == .blaze)
        #expect(FlameStage.stage(for: 14) == .inferno)
        #expect(FlameStage.stage(for: 29) == .inferno)
        #expect(FlameStage.stage(for: 30) == .supernova)
        #expect(FlameStage.stage(for: 100) == .supernova)
    }

    @Test func flameStage_demoted() {
        #expect(FlameStage.ember.demoted == .ember)
        #expect(FlameStage.spark.demoted == .ember)
        #expect(FlameStage.flame.demoted == .spark)
        #expect(FlameStage.blaze.demoted == .flame)
        #expect(FlameStage.inferno.demoted == .blaze)
        #expect(FlameStage.supernova.demoted == .inferno)
    }
}
