import SwiftUI

struct ContentView: View {
    @Bindable var appState: AppState

    @State private var selectedTab = 0
    @State private var showRapidCapture = false
    @State private var showQuestCraft = false
    @State private var showSpinWheel = false
    @State private var showSprint = false
    @State private var selectedQuestForSprint: Quest?

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // Dashboard
                NavigationStack {
                    DashboardView(
                        profile: appState.profile,
                        streak: appState.streak,
                        challenge: appState.todayChallenge,
                        todaySparks: appState.todaySparks,
                        onPickQuest: { selectedTab = 1 },
                        onSpin: { showSpinWheel = true },
                        onSprint: {
                            let quests = appState.questSurfacing.fetchActiveQuests()
                            if let first = quests.first {
                                selectedQuestForSprint = first
                                showSprint = true
                            }
                        }
                    )
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

                // Quest Board
                NavigationStack {
                    QuestBoardView(
                        sparkEngine: appState.sparkEngine,
                        profile: appState.profile,
                        questSurfacing: appState.questSurfacing
                    )
                }
                .tabItem {
                    Label("Quests", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(1)

                // Center placeholder for floating button
                Color.clear
                    .tabItem {
                        Label("", systemImage: "plus")
                    }
                    .tag(2)

                // Progress
                NavigationStack {
                    ProgressTabView(profile: appState.profile, streak: appState.streak, sparkEngine: appState.sparkEngine)
                }
                .tabItem {
                    Label("Progress", systemImage: "map.fill")
                }
                .tag(3)

                // Settings
                NavigationStack {
                    SettingsView(profile: appState.profile)
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
            }
            .tint(SparkTheme.electricPurple)
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: selectedTab)

            // Floating capture button
            captureButton
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showRapidCapture) {
            RapidCaptureView()
                .presentationBackground(SparkTheme.darkBackground)
        }
        .sheet(isPresented: $showQuestCraft) {
            QuestCraftView()
                .presentationBackground(SparkTheme.darkBackground)
        }
        .sheet(isPresented: $showSpinWheel) {
            SpinWheelView(
                quests: appState.questSurfacing.fetchQuestsForWheel(),
                onQuestSelected: { quest in
                    showSpinWheel = false
                    selectedQuestForSprint = quest
                    showSprint = true
                }
            )
            .presentationBackground(SparkTheme.darkBackground)
        }
        .fullScreenCover(isPresented: $showSprint) {
            if let quest = selectedQuestForSprint {
                QuestTimerView(
                    quest: quest,
                    sparkEngine: appState.sparkEngine,
                    profile: appState.profile,
                    onComplete: {
                        showSprint = false
                        appState.streakManager.recordActivity(streak: appState.streak)
                    },
                    onCancel: {
                        showSprint = false
                    }
                )
                .interactiveDismissDisabled(true)
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 2 {
                // Intercept center tab — show capture options
                selectedTab = 0
                showCaptureOptions()
            }
        }
    }

    // MARK: - Floating Capture Button

    private var captureButton: some View {
        Menu {
            Button {
                showRapidCapture = true
                HapticsManager.buttonTap()
            } label: {
                Label("Quick Add", systemImage: "bolt.fill")
            }

            Button {
                showQuestCraft = true
                HapticsManager.buttonTap()
            } label: {
                Label("Craft Quest", systemImage: "wand.and.stars")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(SparkTheme.electricPurple)
                    .frame(width: 56, height: 56)
                    .shadow(color: SparkTheme.electricPurple.opacity(0.4), radius: 8, y: 2)

                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .offset(y: -26)
        .accessibilityLabel("Add quest")
        .accessibilityHint("Opens menu to quickly add or craft a quest")
    }

    private func showCaptureOptions() {
        showRapidCapture = true
    }
}

// MARK: - Progress Tab

struct ProgressTabView: View {
    @Bindable var profile: PlayerProfile
    let streak: Streak
    var sparkEngine: SparkEngine

    var body: some View {
        List {
            NavigationLink {
                ProgressMapView(profile: profile)
            } label: {
                Label("Journey Map", systemImage: "map.fill")
                    .foregroundStyle(SparkTheme.primaryText)
            }
            .listRowBackground(SparkTheme.cardBackground)

            NavigationLink {
                AchievementsView()
            } label: {
                Label("Achievements", systemImage: "trophy.fill")
                    .foregroundStyle(SparkTheme.primaryText)
            }
            .listRowBackground(SparkTheme.cardBackground)

            NavigationLink {
                PowerUpShopView(
                    profile: profile,
                    sparkEngine: sparkEngine
                )
            } label: {
                Label("Power-Up Shop", systemImage: "bag.fill")
                    .foregroundStyle(SparkTheme.primaryText)
            }
            .listRowBackground(SparkTheme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(SparkTheme.darkBackground)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .foregroundStyle(SparkTheme.primaryText)
    }
}
