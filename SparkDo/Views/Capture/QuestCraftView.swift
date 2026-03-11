import SwiftUI
import SwiftData

struct QuestCraftView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var xpValue: Double = 25
    @State private var energyLevel: EnergyLevel = .medium
    @State private var estimatedMinutes: Int = 15
    @State private var notes = ""
    @State private var isEpic = false
    @State private var epicMotivation = ""
    @State private var isQuestChain = false
    @State private var chainSteps: [String] = [""]

    private let timeOptions = [5, 10, 15, 30, 60]

    var body: some View {
        NavigationStack {
            ZStack {
                SparkTheme.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quest Name")
                                .font(SparkTypography.caption())
                                .foregroundStyle(SparkTheme.secondaryText)

                            TextField("What's the quest?", text: $title)
                                .font(SparkTypography.questCard())
                                .foregroundStyle(SparkTheme.primaryText)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(SparkTheme.surfaceBackground)
                                )
                        }

                        // XP Slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("XP Value")
                                    .font(SparkTypography.caption())
                                    .foregroundStyle(SparkTheme.secondaryText)

                                Spacer()

                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill")
                                        .foregroundStyle(SparkTheme.sunshineYellow)
                                    Text("\(Int(xpValue))")
                                        .font(SparkTypography.subheading())
                                        .foregroundStyle(SparkTheme.sunshineYellow)
                                        .monospacedDigit()
                                }
                            }

                            Slider(value: $xpValue, in: 5...100, step: 5)
                                .tint(SparkTheme.electricPurple)
                        }

                        // Energy Level
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Energy Level")
                                .font(SparkTypography.caption())
                                .foregroundStyle(SparkTheme.secondaryText)

                            HStack(spacing: 10) {
                                ForEach(EnergyLevel.allCases) { level in
                                    Button {
                                        energyLevel = level
                                        HapticsManager.buttonTap()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(level.emoji)
                                            Text(level.label)
                                                .font(SparkTypography.caption(13))
                                        }
                                        .foregroundStyle(
                                            energyLevel == level
                                                ? .white
                                                : SparkTheme.secondaryText
                                        )
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(
                                                    energyLevel == level
                                                        ? SparkTheme.energyColor(for: level).opacity(0.6)
                                                        : SparkTheme.cardBackground
                                                )
                                        )
                                    }
                                }
                            }
                        }

                        // Estimated Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Estimated Time")
                                .font(SparkTypography.caption())
                                .foregroundStyle(SparkTheme.secondaryText)

                            HStack(spacing: 8) {
                                ForEach(timeOptions, id: \.self) { minutes in
                                    Button {
                                        estimatedMinutes = minutes
                                        HapticsManager.buttonTap()
                                    } label: {
                                        Text("\(minutes)m")
                                            .font(SparkTypography.caption(14))
                                            .foregroundStyle(
                                                estimatedMinutes == minutes
                                                    ? .white
                                                    : SparkTheme.secondaryText
                                            )
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(
                                                        estimatedMinutes == minutes
                                                            ? SparkTheme.teal
                                                            : SparkTheme.cardBackground
                                                    )
                                            )
                                    }
                                }
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (optional)")
                                .font(SparkTypography.caption())
                                .foregroundStyle(SparkTheme.secondaryText)

                            TextField("Any extra details...", text: $notes, axis: .vertical)
                                .font(SparkTypography.body())
                                .foregroundStyle(SparkTheme.primaryText)
                                .lineLimit(3...6)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(SparkTheme.surfaceBackground)
                                )
                        }

                        // Make it Epic toggle
                        Toggle(isOn: $isEpic) {
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(SparkTheme.sunshineYellow)
                                Text("Make it Epic")
                                    .font(SparkTypography.body())
                                    .foregroundStyle(SparkTheme.primaryText)
                            }
                        }
                        .tint(SparkTheme.sunshineYellow)

                        if isEpic {
                            TextField("Why does this quest matter?", text: $epicMotivation, axis: .vertical)
                                .font(SparkTypography.body())
                                .foregroundStyle(SparkTheme.primaryText)
                                .lineLimit(2...4)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(SparkTheme.surfaceBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(SparkTheme.sunshineYellow.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Quest Chain toggle
                        Toggle(isOn: $isQuestChain) {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                    .foregroundStyle(SparkTheme.teal)
                                Text("Quest Chain")
                                    .font(SparkTypography.body())
                                    .foregroundStyle(SparkTheme.primaryText)
                            }
                        }
                        .tint(SparkTheme.teal)

                        if isQuestChain {
                            questChainSection
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Create button
                        Button {
                            createQuest()
                        } label: {
                            Text("Create Quest")
                                .font(SparkTypography.subheading())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(title.isEmpty ? SparkTheme.tertiaryText : SparkTheme.electricPurple)
                                )
                                .glow(color: title.isEmpty ? .clear : SparkTheme.electricPurple, radius: 6)
                        }
                        .disabled(title.isEmpty)
                    }
                    .padding()
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isEpic)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isQuestChain)
                }
            }
            .navigationTitle("Craft a Quest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(SparkTheme.secondaryText)
                }
            }
        }
    }

    // MARK: - Quest Chain

    private var questChainSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chain Steps")
                .font(SparkTypography.caption())
                .foregroundStyle(SparkTheme.secondaryText)

            ForEach(Array(chainSteps.enumerated()), id: \.offset) { index, _ in
                HStack {
                    Text("\(index + 1).")
                        .font(SparkTypography.caption())
                        .foregroundStyle(SparkTheme.tertiaryText)
                        .frame(width: 24)

                    TextField("Step \(index + 1)", text: $chainSteps[index])
                        .font(SparkTypography.body())
                        .foregroundStyle(SparkTheme.primaryText)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(SparkTheme.surfaceBackground)
                        )

                    if chainSteps.count > 1 {
                        Button {
                            chainSteps.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(SparkTheme.coral)
                        }
                    }
                }
            }

            Button {
                chainSteps.append("")
                HapticsManager.buttonTap()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Step")
                }
                .font(SparkTypography.caption())
                .foregroundStyle(SparkTheme.teal)
            }
        }
    }

    // MARK: - Create

    private func createQuest() {
        let quest = Quest(
            title: title,
            xpValue: Int(xpValue),
            energyLevel: energyLevel,
            estimatedMinutes: estimatedMinutes,
            notes: notes,
            isEpic: isEpic,
            epicMotivation: epicMotivation
        )
        modelContext.insert(quest)

        // Create chain children if quest chain is enabled
        if isQuestChain {
            let steps = chainSteps.filter { !$0.isEmpty }
            for (index, step) in steps.enumerated() {
                let child = Quest(
                    title: step,
                    xpValue: max(5, Int(xpValue) / steps.count),
                    energyLevel: energyLevel,
                    estimatedMinutes: max(5, estimatedMinutes / steps.count),
                    parentQuest: quest
                )
                child.sortOrder = index
                modelContext.insert(child)
            }
        }

        HapticsManager.questComplete()
        SoundManager.shared.play(.questComplete)
        dismiss()
    }
}
