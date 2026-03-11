import SwiftUI
import SwiftData

struct WeeklyRecapView: View {
    let profile: PlayerProfile
    let questsThisWeek: Int
    let sparksThisWeek: Int
    let minutesSprinted: Int
    let biggestQuest: Quest?
    let streak: Streak

    @State private var currentSlide = 0
    @State private var appear = false
    @Environment(\.dismiss) private var dismiss

    private let totalSlides = 5

    var body: some View {
        ZStack {
            SparkTheme.darkBackground.ignoresSafeArea()

            // Progress dots
            VStack {
                HStack(spacing: 6) {
                    ForEach(0..<totalSlides, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentSlide ? SparkTheme.electricPurple : SparkTheme.cardBackground)
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Spacer()
            }

            // Slides
            TabView(selection: $currentSlide) {
                weekInNumbersSlide.tag(0)
                biggestQuestSlide.tag(1)
                streakSlide.tag(2)
                levelProgressSlide.tag(3)
                nextWeekSlide.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(SparkTheme.secondaryText)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appear = true
            }
        }
    }

    // MARK: - Slide 1: Week in Numbers

    private var weekInNumbersSlide: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Your Week")
                .font(SparkTypography.heading(32))
                .foregroundStyle(SparkTheme.primaryText)

            VStack(spacing: 24) {
                RecapStat(value: "\(questsThisWeek)", label: "Quests Completed", color: SparkTheme.mintGreen)
                RecapStat(value: "\(sparksThisWeek)", label: "Sparks Earned", color: SparkTheme.sunshineYellow)
                RecapStat(value: "\(minutesSprinted)m", label: "Focus Time", color: SparkTheme.teal)
            }

            Spacer()

            swipeHint
        }
        .padding()
    }

    // MARK: - Slide 2: Biggest Quest

    private var biggestQuestSlide: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(SparkTheme.sunshineYellow)

            Text("Biggest Quest")
                .font(SparkTypography.heading(28))
                .foregroundStyle(SparkTheme.primaryText)

            if let quest = biggestQuest {
                Text(quest.title)
                    .font(SparkTypography.subheading(22))
                    .foregroundStyle(SparkTheme.secondaryText)
                    .multilineTextAlignment(.center)

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(SparkTheme.sunshineYellow)
                    Text("\(quest.xpValue) XP")
                        .font(SparkTypography.subheading())
                        .foregroundStyle(SparkTheme.sunshineYellow)
                }
            } else {
                Text("No quests this week")
                    .font(SparkTypography.body())
                    .foregroundStyle(SparkTheme.tertiaryText)
            }

            Spacer()

            swipeHint
        }
        .padding()
    }

    // MARK: - Slide 3: Streak

    private var streakSlide: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 60 * streak.flameStage.flameScale))
                .foregroundStyle(SparkTheme.coral)
                .pulseGlow(color: SparkTheme.coral)

            Text("Streak Status")
                .font(SparkTypography.heading(28))
                .foregroundStyle(SparkTheme.primaryText)

            Text("\(streak.currentDays) Days")
                .font(SparkTypography.heading(36))
                .foregroundStyle(SparkTheme.sunshineYellow)

            Text(streak.flameStage.label)
                .font(SparkTypography.subheading())
                .foregroundStyle(SparkTheme.secondaryText)

            Spacer()

            swipeHint
        }
        .padding()
    }

    // MARK: - Slide 4: Level Progress

    private var levelProgressSlide: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Level \(profile.level)")
                .font(SparkTypography.heading(40))
                .foregroundStyle(SparkTheme.electricPurple)
                .glow(color: SparkTheme.electricPurple, radius: 10)

            Text("Level Progress")
                .font(SparkTypography.heading(28))
                .foregroundStyle(SparkTheme.primaryText)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SparkTheme.cardBackground)
                        .frame(height: 16)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(SparkTheme.primaryGradient)
                        .frame(width: geo.size.width * profile.levelProgress, height: 16)
                }
            }
            .frame(height: 16)
            .padding(.horizontal, 40)

            Text("\(profile.totalSparks) / \(profile.sparksForNextLevel) Sparks")
                .font(SparkTypography.body())
                .foregroundStyle(SparkTheme.secondaryText)

            Spacer()

            swipeHint
        }
        .padding()
    }

    // MARK: - Slide 5: Next Week

    private var nextWeekSlide: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(SparkTheme.sunshineYellow)

            Text("Ready for Next Week?")
                .font(SparkTypography.heading(28))
                .foregroundStyle(SparkTheme.primaryText)

            Text("New daily challenges await.\nKeep that flame burning!")
                .font(SparkTypography.body())
                .foregroundStyle(SparkTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Let's Go!")
                    .font(SparkTypography.subheading())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(SparkTheme.electricPurple)
                    )
                    .glow(color: SparkTheme.electricPurple, radius: 10)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private var swipeHint: some View {
        Text("Swipe to continue")
            .font(SparkTypography.caption(12))
            .foregroundStyle(SparkTheme.tertiaryText)
            .padding(.bottom, 32)
    }
}

struct RecapStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(SparkTypography.heading(36))
                .foregroundStyle(color)

            Text(label)
                .font(SparkTypography.caption())
                .foregroundStyle(SparkTheme.secondaryText)
        }
    }
}
