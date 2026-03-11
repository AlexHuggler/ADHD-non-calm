import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Quest> { $0.status == .completed },
           sort: \Quest.completedAt, order: .reverse)
    private var recentWins: [Quest]

    @Bindable var profile: PlayerProfile
    let streak: Streak
    let challenge: DailyChallenge
    let todaySparks: Int

    var onPickQuest: () -> Void = {}
    var onSpin: () -> Void = {}
    var onSprint: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Spark Counter
                SparkCounterView(
                    totalSparks: profile.totalSparks,
                    todaySparks: todaySparks,
                    level: profile.level,
                    levelProgress: profile.levelProgress
                )

                // Daily Challenge
                DailyChallengeCard(challenge: challenge)

                // Quick Actions
                quickActionsRow

                // Streak Flame
                HStack {
                    StreakFlameView(streak: streak)
                    Spacer()
                }

                // Recent Wins
                if !recentWins.isEmpty {
                    recentWinsSection
                }
            }
            .padding()
        }
        .background(SparkTheme.darkBackground)
        .navigationTitle("SparkDo")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "Pick a Quest",
                icon: "target",
                color: SparkTheme.teal,
                action: onPickQuest
            )

            QuickActionButton(
                title: "Spin!",
                icon: "circle.dotted",
                color: SparkTheme.coral,
                action: onSpin
            )

            QuickActionButton(
                title: "Sprint",
                icon: "bolt.fill",
                color: SparkTheme.sunshineYellow,
                action: onSprint
            )
        }
    }

    // MARK: - Recent Wins

    private var recentWinsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Wins")
                .font(SparkTypography.subheading(16))
                .foregroundStyle(SparkTheme.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recentWins.prefix(5)) { quest in
                        RecentWinCard(quest: quest)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            HapticsManager.buttonTap()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)

                Text(title)
                    .font(SparkTypography.caption(12))
                    .foregroundStyle(SparkTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SparkTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Recent Win Card

struct RecentWinCard: View {
    let quest: Quest

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(quest.title)
                .font(SparkTypography.caption(13))
                .foregroundStyle(SparkTheme.primaryText)
                .lineLimit(2)

            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(SparkTheme.sunshineYellow)

                Text("\(quest.xpValue)")
                    .font(SparkTypography.caption(12))
                    .foregroundStyle(SparkTheme.sunshineYellow)
            }
        }
        .padding(10)
        .frame(width: 120, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(SparkTheme.surfaceBackground)
        )
    }
}
