import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Quest> { $0.status == .completed },
           sort: \Quest.completedAt, order: .reverse)
    private var recentWins: [Quest]

    @Query(filter: #Predicate<Quest> { $0.status == .active },
           sort: \Quest.createdAt, order: .reverse)
    private var activeQuests: [Quest]

    @Bindable var profile: PlayerProfile
    let streak: Streak
    @Bindable var challenge: DailyChallenge
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

                // Today's Focus — hero card highlighting next quest
                if let focusQuest = activeQuests.first {
                    todaysFocusCard(quest: focusQuest)
                }

                // Daily Challenge
                DailyChallengeCard(challenge: challenge)

                // Quick Actions (enhanced hierarchy)
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
        .refreshable { }
        .background(SparkTheme.darkBackground)
        .navigationTitle("SparkDo")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Today's Focus Hero Card

    private func todaysFocusCard(quest: Quest) -> some View {
        Button {
            HapticsManager.buttonTap()
            onPickQuest()
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEXT UP")
                        .font(SparkTypography.caption(11))
                        .fontWeight(.bold)
                        .foregroundStyle(SparkTheme.teal)
                        .tracking(1.2)

                    Text(quest.title)
                        .font(SparkTypography.subheading(18))
                        .foregroundStyle(SparkTheme.primaryText)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        XPBadge(value: quest.xpValue, size: .small)

                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text("\(quest.estimatedMinutes)m")
                                .font(SparkTypography.caption(11))
                        }
                        .foregroundStyle(SparkTheme.tertiaryText)
                    }
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(SparkTheme.teal)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SparkTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(SparkTheme.teal.opacity(0.3), lineWidth: 1)
                    )
            )
            .glow(color: SparkTheme.teal, radius: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Next up: \(quest.title), \(quest.xpValue) XP")
        .accessibilityHint("Tap to go to quest board")
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "Pick a Quest",
                icon: "target",
                color: SparkTheme.teal,
                isPrimary: true,
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
    var isPrimary: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            HapticsManager.buttonTap()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: isPrimary ? 28 : 24))
                    .foregroundStyle(color)

                Text(title)
                    .font(SparkTypography.caption(isPrimary ? 13 : 12))
                    .fontWeight(isPrimary ? .semibold : .medium)
                    .foregroundStyle(SparkTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isPrimary ? 20 : 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isPrimary
                        ? color.opacity(0.15)
                        : SparkTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(color.opacity(isPrimary ? 0.5 : 0.3), lineWidth: isPrimary ? 1.5 : 1)
                    )
            )
            .glow(color: isPrimary ? color : .clear, radius: isPrimary ? 6 : 0)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .accessibilityLabel(title)
    }
}

#Preview {
    NavigationStack {
        DashboardView(
            profile: PreviewSampleData.sampleProfile,
            streak: PreviewSampleData.sampleStreak,
            challenge: PreviewSampleData.sampleChallenge,
            todaySparks: 45
        )
    }
    .modelContainer(PreviewSampleData.container)
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

            XPBadge(value: quest.xpValue, suffix: "", size: .small)
        }
        .padding(10)
        .frame(width: 120, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(SparkTheme.surfaceBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quest.title), \(quest.xpValue) XP")
    }
}
