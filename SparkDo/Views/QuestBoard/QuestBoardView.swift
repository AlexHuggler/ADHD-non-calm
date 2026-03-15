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
    @State private var showUndoToast = false
    @State private var undoQuest: Quest?
    @State private var undoTransactions: [SparkTransaction] = []
    @State private var skippedQuests: [Quest] = []
    @State private var showRapidCapture = false
    @State private var showLevelUp = false
    @State private var newLevel = 0
    @State private var showQuestToast = false
    @State private var sessionCompletedCount = 0

    var sparkEngine: SparkEngine
    var profile: PlayerProfile
    var questSurfacing: QuestSurfacingEngine

    var body: some View {
        ZStack {
            SparkTheme.darkBackground.ignoresSafeArea()

            VStack {
                if quests.isEmpty && skippedQuests.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    questList
                }
            }

            // Undo toast
            if showUndoToast {
                VStack {
                    Spacer()
                    undoToast
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showUndoToast)
            }
        }
        .confetti(isActive: $showConfetti)
        .toast(isPresented: $showQuestToast, icon: "checkmark.circle.fill", message: sessionCompletedCount > 1 ? "On fire! \(sessionCompletedCount) quests today!" : "Quest completed!")
        .overlay {
            if showLevelUp {
                LevelUpCelebrationView(newLevel: newLevel) {
                    showLevelUp = false
                }
                .transition(.opacity)
            }
        }
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
        .sheet(isPresented: $showRapidCapture) {
            RapidCaptureView()
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

                // Skipped quests section
                if !skippedQuests.isEmpty {
                    skippedSection
                }
            }
            .padding()
        }
        .refreshable {
            refreshQuests()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "trophy.fill",
            title: "Quest board is clear!",
            message: "You're a legend.\nTime to capture new adventures.",
            iconColor: SparkTheme.sunshineYellow,
            action: {
                showRapidCapture = true
            },
            actionLabel: "Add a Quest"
        )
    }

    // MARK: - Skipped Section

    private var skippedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Skipped")
                .font(SparkTypography.subheading(14))
                .foregroundStyle(SparkTheme.tertiaryText)
                .padding(.top, 12)

            ForEach(skippedQuests) { quest in
                HStack {
                    Text(quest.title)
                        .font(SparkTypography.body())
                        .foregroundStyle(SparkTheme.secondaryText)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        quest.reactivate()
                        HapticsManager.buttonTap()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            refreshQuests()
                        }
                    } label: {
                        Text("Restore")
                            .font(SparkTypography.caption(12))
                            .foregroundStyle(SparkTheme.teal)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(SparkTheme.teal.opacity(0.15))
                            )
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(SparkTheme.cardBackground.opacity(0.5))
                )
            }
        }
    }

    // MARK: - Undo Toast

    private var undoToast: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(SparkTheme.mintGreen)

            Text("Quest completed!")
                .font(SparkTypography.body())
                .foregroundStyle(SparkTheme.primaryText)

            Spacer()

            Button {
                undoLastCompletion()
            } label: {
                Text("Undo")
                    .font(SparkTypography.subheading(14))
                    .foregroundStyle(SparkTheme.coral)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SparkTheme.cardBackground)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Actions

    private func completeQuest(_ quest: Quest) {
        let previousLevel = profile.level
        let transactions = sparkEngine.completeQuest(quest, profile: profile)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            refreshQuests()
        }
        showConfetti = true
        sessionCompletedCount += 1

        // Level-up check
        if profile.level > previousLevel {
            newLevel = profile.level
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                withAnimation { showLevelUp = true }
            }
        }

        // Show undo toast
        undoQuest = quest
        undoTransactions = transactions
        withAnimation { showUndoToast = true }

        // Auto-dismiss undo toast, then show quest toast
        Task {
            try? await Task.sleep(for: .seconds(5))
            withAnimation { showUndoToast = false }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation { showQuestToast = true }
        }
    }

    private func undoLastCompletion() {
        guard let quest = undoQuest else { return }
        sparkEngine.undoQuestCompletion(quest, transactions: undoTransactions, profile: profile)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showUndoToast = false
            refreshQuests()
        }
        HapticsManager.buttonTap()
    }

    private func skipQuest(_ quest: Quest) {
        quest.status = .skipped
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            refreshQuests()
        }
    }

    private func refreshQuests() {
        quests = questSurfacing.fetchActiveQuests(sortedBy: sortMode)
        refreshSkippedQuests()
    }

    private func refreshSkippedQuests() {
        let descriptor = FetchDescriptor<Quest>(
            predicate: #Predicate { $0.status == .skipped }
        )
        skippedQuests = (try? modelContext.fetch(descriptor)) ?? []
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
