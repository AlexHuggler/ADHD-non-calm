import SwiftUI
import SwiftData

struct QuestBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var sortMode: QuestSurfacingEngine.SortMode = .shuffle
    @State private var quests: [Quest] = []
    @State private var showConfetti = false
    @State private var showSpinWheel = false
    @State private var showQuestTimer = false
    @State private var selectedQuest: Quest?

    var sparkEngine: SparkEngine
    var profile: PlayerProfile
    var questSurfacing: QuestSurfacingEngine

    var body: some View {
        ZStack {
            SparkTheme.darkBackground.ignoresSafeArea()

            if quests.isEmpty {
                emptyState
            } else {
                questList
            }
        }
        .confetti(isActive: $showConfetti)
        .navigationTitle("Quest Board")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(QuestSurfacingEngine.SortMode.allCases) { mode in
                        Button {
                            sortMode = mode
                            refreshQuests()
                        } label: {
                            Label(mode.rawValue, systemImage: sortIcon(for: mode))
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .foregroundStyle(SparkTheme.teal)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSpinWheel = true
                } label: {
                    Image(systemName: "circle.dotted")
                        .foregroundStyle(SparkTheme.coral)
                }
            }
        }
        .sheet(isPresented: $showSpinWheel) {
            SpinWheelView(
                quests: quests,
                onQuestSelected: { quest in
                    selectedQuest = quest
                    showSpinWheel = false
                    showQuestTimer = true
                }
            )
        }
        .fullScreenCover(isPresented: $showQuestTimer) {
            if let quest = selectedQuest {
                QuestTimerView(
                    quest: quest,
                    sparkEngine: sparkEngine,
                    profile: profile,
                    onComplete: {
                        showQuestTimer = false
                        showConfetti = true
                        refreshQuests()
                    },
                    onCancel: {
                        showQuestTimer = false
                    }
                )
            }
        }
        .onAppear {
            refreshQuests()
        }
    }

    // MARK: - Quest List

    private var questList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(quests) { quest in
                    QuestCardView(
                        quest: quest,
                        onComplete: {
                            completeQuest(quest)
                        },
                        onSkip: {
                            skipQuest(quest)
                        },
                        onTap: {
                            selectedQuest = quest
                            showQuestTimer = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .slide.combined(with: .opacity)
                    ))
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(SparkTheme.sunshineYellow)

            Text("Quest board is clear!")
                .font(SparkTypography.heading(24))
                .foregroundStyle(SparkTheme.primaryText)

            Text("You're a legend.\nTime to capture new adventures.")
                .font(SparkTypography.body())
                .foregroundStyle(SparkTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Actions

    private func completeQuest(_ quest: Quest) {
        let _ = sparkEngine.completeQuest(quest, profile: profile)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            refreshQuests()
        }
        showConfetti = true
    }

    private func skipQuest(_ quest: Quest) {
        quest.status = .skipped
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            refreshQuests()
        }
    }

    private func refreshQuests() {
        quests = questSurfacing.fetchActiveQuests(sortedBy: sortMode)
    }

    private func sortIcon(for mode: QuestSurfacingEngine.SortMode) -> String {
        switch mode {
        case .shuffle: "shuffle"
        case .quickest: "clock"
        case .mostSparks: "bolt.fill"
        }
    }
}

#Preview {
    let container = PreviewSampleData.container
    let context = container.mainContext
    let profile = PreviewSampleData.sampleProfile
    context.insert(profile)
    return NavigationStack {
        QuestBoardView(
            sparkEngine: SparkEngine(modelContext: context),
            profile: profile,
            questSurfacing: QuestSurfacingEngine(modelContext: context)
        )
    }
    .modelContainer(container)
}
