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
    @State private var showSwipeHint = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .toast(isPresented: $showQuestToast, icon: sessionCompletedCount >= 3 ? "flame.fill" : "checkmark.circle.fill", message: comboMessage, iconColor: sessionCompletedCount >= 3 ? SparkTheme.coral : SparkTheme.mintGreen)
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
                .interactiveDismissDisabled(true)
            }
        }
        .sheet(isPresented: $showRapidCapture) {
            RapidCaptureView()
        }
        .onAppear {
            refreshQuests()
            // Show swipe hint on first launch
            if !UserDefaults.standard.bool(forKey: "hasSeenSwipeHint") && !quests.isEmpty {
                withAnimation(.easeIn(duration: 0.3).delay(0.5)) {
                    showSwipeHint = true
                }
                Task {
                    try? await Task.sleep(for: .seconds(3.5))
                    withAnimation { showSwipeHint = false }
                    UserDefaults.standard.set(true, forKey: "hasSeenSwipeHint")
                }
            }
        }
    }

    // MARK: - Quest List

    private var questList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(quests.enumerated()), id: \.element.id) { index, quest in
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
                    .opacity(reduceMotion ? 1 : 1)
                    .animation(
                        reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.05),
                        value: quests.count
                    )
                    .overlay(alignment: .center) {
                        // First-launch swipe hint on first card only
                        if index == 0 && showSwipeHint {
                            SwipeHintOverlay()
                                .allowsHitTesting(false)
                                .transition(.opacity)
                        }
                    }
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
        let hour = Calendar.current.component(.hour, from: Date())
        let (message, icon, color): (String, String, Color) = {
            if hour < 12 {
                return ("Fresh morning, fresh start!\nEven one tiny quest counts.", "sunrise.fill", SparkTheme.sunshineYellow)
            } else if hour < 17 {
                return ("Board's clear — you crushed it!\nReady for more?", "trophy.fill", SparkTheme.sunshineYellow)
            } else {
                return ("Winding down? Add a small\nwin to end the day strong.", "moon.stars.fill", SparkTheme.teal)
            }
        }()

        return EmptyStateView(
            icon: icon,
            title: "Quest board is clear!",
            message: message,
            iconColor: color,
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

    private var comboMessage: String {
        switch sessionCompletedCount {
        case 0...1: "Quest completed!"
        case 2: "2x Combo! Keep going!"
        case 3: "3x STREAK! On fire!"
        case 4...5: "\(sessionCompletedCount)x COMBO! Unstoppable!"
        default: "\(sessionCompletedCount)x LEGENDARY STREAK!"
        }
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

// MARK: - Swipe Hint Overlay (2.6)

struct SwipeHintOverlay: View {
    @State private var offsetX: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 14, weight: .semibold))
            Text("Swipe to complete or skip")
                .font(SparkTypography.caption(13))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(SparkTheme.electricPurple.opacity(0.85))
                .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
        )
        .offset(x: offsetX)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)) {
                offsetX = 20
            }
        }
    }
}
