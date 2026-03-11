import SwiftUI
import SwiftData

struct RapidCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var parsedQuests: [(String, Int)] = []
    @State private var isAdding = false
    @State private var addedCount = 0
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                SparkTheme.darkBackground.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Input area
                    TextEditor(text: $inputText)
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(SparkTheme.primaryText)
                        .scrollContentBackground(.hidden)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(SparkTheme.surfaceBackground)
                        )
                        .frame(minHeight: 150)
                        .focused($isInputFocused)
                        .onChange(of: inputText) { _, newValue in
                            parseQuests(from: newValue)
                        }

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
                                            HStack(spacing: 4) {
                                                Image(systemName: "bolt.fill")
                                                    .font(.system(size: 11))
                                                Text("\(quest.1)")
                                                    .font(SparkTypography.caption(13))
                                            }
                                            .foregroundStyle(SparkTheme.sunshineYellow)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(SparkTheme.sunshineYellow.opacity(0.15))
                                            )
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
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            parsedQuests = lines.map { line in
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

                let quest = Quest(title: title, xpValue: xp)
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
