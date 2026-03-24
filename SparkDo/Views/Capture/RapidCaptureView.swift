import SwiftUI
import SwiftData

struct RapidCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var parsedQuests: [(String, Int)] = []
    @State private var isAdding = false
    @State private var addedCount = 0
    @State private var showShortEntryWarning = false
    @FocusState private var isInputFocused: Bool

    // Quick template categories for brain dump
    private let templates: [(String, String, [String])] = [
        ("Chores", "house.fill", ["Do laundry", "Clean kitchen", "Take out trash", "Vacuum living room"]),
        ("Work", "briefcase.fill", ["Check emails", "Review PRs", "Update docs", "Team standup"]),
        ("Health", "heart.fill", ["Drink water", "10 min walk", "Stretch break", "Prep healthy meal"]),
        ("Errands", "car.fill", ["Grocery run", "Pick up package", "Return item", "Schedule appointment"]),
        ("Self-care", "leaf.fill", ["Meditate 5 min", "Journal", "Read 10 pages", "Tidy desk"]),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                SparkTheme.darkBackground.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Quick templates row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(templates, id: \.0) { template in
                                Button {
                                    let newText = template.2.joined(separator: "\n")
                                    inputText = inputText.isEmpty ? newText : inputText + "\n" + newText
                                    HapticsManager.buttonTap()
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: template.1)
                                            .font(.system(size: 11))
                                        Text(template.0)
                                            .font(SparkTypography.caption(12))
                                    }
                                    .foregroundStyle(SparkTheme.secondaryText)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(SparkTheme.cardBackground)
                                            .overlay(
                                                Capsule()
                                                    .stroke(SparkTheme.tertiaryText.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                    }

                    // Input area
                    ZStack(alignment: .topLeading) {
                        if inputText.isEmpty {
                            Text("Type one quest per line...\n\nDo laundry\nCall dentist\nReview notes\nClean desk")
                                .font(.system(size: 18, weight: .regular, design: .rounded))
                                .foregroundStyle(SparkTheme.tertiaryText)
                                .padding(20)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $inputText)
                            .font(.system(size: 18, weight: .regular, design: .rounded))
                            .foregroundStyle(SparkTheme.primaryText)
                            .textInputAutocapitalization(.sentences)
                            .scrollContentBackground(.hidden)
                            .padding(16)
                            .focused($isInputFocused)
                            .onChange(of: inputText) { _, newValue in
                                parseQuests(from: newValue)
                            }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(SparkTheme.surfaceBackground)
                    )
                    .frame(minHeight: 150)

                    if !parsedQuests.isEmpty {
                        // Parsed quests preview
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(Array(parsedQuests.enumerated()), id: \.offset) { index, quest in
                                    HStack {
                                        Text(quest.0)
                                            .font(SparkTypography.body())
                                            .foregroundStyle(SparkTheme.primaryText)
                                            .lineLimit(2)

                                        Spacer()

                                        Button {
                                            adjustXP(at: index)
                                        } label: {
                                            XPBadgePill(value: quest.1)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(SparkTheme.cardBackground)
                                    )
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                }
                            }
                        }

                        if showShortEntryWarning {
                            Text("Quests need at least 2 characters")
                                .font(SparkTypography.caption(12))
                                .foregroundStyle(SparkTheme.coral)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Add all button
                        Button {
                            addAllQuests()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add all \(parsedQuests.count) quests")
                            }
                            .font(SparkTypography.subheading())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(SparkTheme.electricPurple)
                            )
                            .glow(color: SparkTheme.electricPurple, radius: 8)
                        }
                        .sparkPressEffect()
                        .disabled(isAdding)
                    }
                }
                .padding()
            }
            .navigationTitle("Brain Dump")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(SparkTheme.secondaryText)
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }

    // MARK: - Parsing

    private func parseQuests(from text: String) {
        let allLines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let validLines = allLines.filter { $0.count >= 2 }

        // Show warning if any lines were too short
        let hasShortEntries = allLines.count > validLines.count
        if hasShortEntries && !showShortEntryWarning {
            HapticsManager.validationError()
            withAnimation { showShortEntryWarning = true }
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation { showShortEntryWarning = false }
            }
        } else if !hasShortEntries {
            withAnimation { showShortEntryWarning = false }
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            parsedQuests = validLines.map { line in
                (line, Quest.autoXP(for: line))
            }
        }
    }

    private func adjustXP(at index: Int) {
        guard index < parsedQuests.count else { return }
        let current = parsedQuests[index].1
        // Cycle through: 10 → 25 → 50 → 75 → 100 → 10
        let options = [10, 25, 50, 75, 100]
        let nextIndex = (options.firstIndex(of: current).map { $0 + 1 } ?? 0) % options.count
        parsedQuests[index].1 = options[nextIndex]
        HapticsManager.buttonTap()
    }

    // MARK: - Add Quests

    // M2 fix: Use structured concurrency instead of DispatchQueue.main.asyncAfter
    private func addAllQuests() {
        isAdding = true

        Task {
            for (index, (title, xp)) in parsedQuests.enumerated() {
                if index > 0 {
                    try? await Task.sleep(for: .milliseconds(100))
                }

                let quest = Quest(title: title.trimmingCharacters(in: .whitespaces), xpValue: xp)
                modelContext.insert(quest)

                addedCount += 1
                HapticsManager.buttonTap()
                SoundManager.shared.play(.rapidCaptureDing)
            }

            try? await Task.sleep(for: .milliseconds(300))
            dismiss()
        }
    }
}

#Preview {
    RapidCaptureView()
        .modelContainer(PreviewSampleData.container)
}
