import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var achievements: [Achievement]
    @State private var selectedAchievement: Achievement?
    @State private var showDetail = false
    @State private var filter: AchievementFilter = .unlocked

    enum AchievementFilter: String, CaseIterable {
        case all = "All"
        case unlocked = "Unlocked"
        case locked = "Locked"
    }

    private var filteredAchievements: [Achievement] {
        switch filter {
        case .all: achievements
        case .unlocked: achievements.filter { $0.isUnlocked }
        case .locked: achievements.filter { !$0.isUnlocked }
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Filter tabs
            HStack(spacing: 8) {
                ForEach(AchievementFilter.allCases, id: \.rawValue) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            filter = tab
                        }
                        HapticsManager.buttonTap()
                    } label: {
                        Text(tab.rawValue)
                            .font(SparkTypography.caption(13))
                            .foregroundStyle(filter == tab ? .white : SparkTheme.secondaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(filter == tab ? SparkTheme.electricPurple : SparkTheme.cardBackground)
                            )
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            ScrollView {
                if filteredAchievements.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: filter == .unlocked ? "trophy" : "lock")
                            .font(.system(size: 36))
                            .foregroundStyle(SparkTheme.tertiaryText)

                        Text(filter == .unlocked ? "No achievements unlocked yet" : "All achievements unlocked!")
                            .font(SparkTypography.body())
                            .foregroundStyle(SparkTheme.secondaryText)
                    }
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementBadge(achievement: achievement)
                                .onTapGesture {
                                    selectedAchievement = achievement
                                    showDetail = true
                                    HapticsManager.buttonTap()
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(SparkTheme.darkBackground)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showDetail) {
            if let achievement = selectedAchievement {
                AchievementDetailSheet(achievement: achievement)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Badge

struct AchievementBadge: View {
    let achievement: Achievement

    @State private var appear = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? rarityColor.opacity(0.2)
                            : SparkTheme.cardBackground
                    )
                    .frame(width: 64, height: 64)

                if achievement.isUnlocked {
                    Image(systemName: achievement.iconName)
                        .font(.system(size: 24))
                        .foregroundStyle(rarityColor)
                } else {
                    Image(systemName: "questionmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(SparkTheme.tertiaryText)
                }

                if achievement.isUnlocked {
                    Circle()
                        .stroke(rarityColor, lineWidth: 2)
                        .frame(width: 64, height: 64)
                }
            }

            Text(achievement.isUnlocked ? achievement.name : "???")
                .font(SparkTypography.caption(11))
                .foregroundStyle(
                    achievement.isUnlocked
                        ? SparkTheme.primaryText
                        : SparkTheme.tertiaryText
                )
                .lineLimit(1)

            Text(achievement.rarity.label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(rarityColor)
        }
        .grayscale(achievement.isUnlocked ? 0 : 0.8)
        .opacity(appear ? 1 : 0)
        .scaleEffect(appear ? 1 : 0.8)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appear = true
            }
        }
    }

    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: SparkTheme.secondaryText
        case .rare: SparkTheme.teal
        case .epic: SparkTheme.electricPurple
        case .legendary: SparkTheme.sunshineYellow
        }
    }
}

// MARK: - Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(rarityColor.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: achievement.isUnlocked ? achievement.iconName : "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(achievement.isUnlocked ? rarityColor : SparkTheme.tertiaryText)
            }
            .glow(color: achievement.isUnlocked ? rarityColor : .clear, radius: 15)

            Text(achievement.name)
                .font(SparkTypography.heading(24))
                .foregroundStyle(SparkTheme.primaryText)

            Text(achievement.descriptionText)
                .font(SparkTypography.body())
                .foregroundStyle(SparkTheme.secondaryText)
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                Circle()
                    .fill(rarityColor)
                    .frame(width: 8, height: 8)
                Text(achievement.rarity.label)
                    .font(SparkTypography.caption())
                    .foregroundStyle(rarityColor)
            }

            if achievement.isUnlocked, let date = achievement.unlockedAt {
                Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(SparkTypography.caption())
                    .foregroundStyle(SparkTheme.tertiaryText)
            }

            Spacer()
        }
        .padding(.top, 32)
        .frame(maxWidth: .infinity)
        .background(SparkTheme.darkBackground)
    }

    private var rarityColor: Color {
        switch achievement.rarity {
        case .common: SparkTheme.secondaryText
        case .rare: SparkTheme.teal
        case .epic: SparkTheme.electricPurple
        case .legendary: SparkTheme.sunshineYellow
        }
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .modelContainer(PreviewSampleData.container)
}
