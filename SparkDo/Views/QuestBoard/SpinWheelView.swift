import SwiftUI
import SwiftData

struct SpinWheelView: View {
    let quests: [Quest]
    var onQuestSelected: (Quest) -> Void = { _ in }

    @State private var rotation: Double = 0
    @State private var isSpinning = false
    @State private var selectedQuest: Quest?
    @State private var showResult = false
    @State private var spinsUsed = 0
    @State private var showNudge = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let maxRespins = 3

    var body: some View {
        NavigationStack {
            ZStack {
                SparkTheme.darkBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    if showResult, let quest = selectedQuest {
                        resultView(quest: quest)
                    } else {
                        wheelContent
                    }
                }
            }
            .navigationTitle("Spin the Wheel!")
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

    // MARK: - Wheel

    private var wheelContent: some View {
        VStack(spacing: 32) {
            Spacer()

            if quests.isEmpty {
                EmptyStateView(
                    icon: "circle.dotted",
                    title: "No quests to spin!",
                    message: "Add some quests first."
                )
            } else {
                // Pointer
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(SparkTheme.sunshineYellow)
                    .glow(color: SparkTheme.sunshineYellow, radius: 8)

                // H8 fix: Use GeometryReader for responsive wheel sizing instead of hardcoded 280
                GeometryReader { geo in
                    let wheelSize = min(geo.size.width, geo.size.height) * 0.85
                    ZStack {
                        ForEach(Array(quests.enumerated()), id: \.element.id) { index, quest in
                            WheelSegment(
                                quest: quest,
                                index: index,
                                total: quests.count
                            )
                        }
                    }
                    .frame(width: wheelSize, height: wheelSize)
                    .rotationEffect(.degrees(rotation))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .onTapGesture {
                    if !isSpinning {
                        spin()
                    }
                }

                // Spin button
                Button {
                    spin()
                } label: {
                    Text(isSpinning ? "Spinning..." : "SPIN!")
                        .font(SparkTypography.heading(20))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(isSpinning ? SparkTheme.tertiaryText : SparkTheme.coral)
                        )
                        .glow(color: isSpinning ? .clear : SparkTheme.coral, radius: 10)
                }
                .disabled(isSpinning || quests.isEmpty)

                if showNudge {
                    Text("Trust the wheel!")
                        .font(SparkTypography.caption())
                        .foregroundStyle(SparkTheme.sunshineYellow)
                        .transition(.opacity)
                }
            }

            Spacer()
        }
    }

    // MARK: - Result

    private func resultView(quest: Quest) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(SparkTheme.sunshineYellow)

            Text(quest.title)
                .font(SparkTypography.heading(28))
                .foregroundStyle(SparkTheme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Label("\(quest.xpValue) XP", systemImage: "bolt.fill")
                    .font(SparkTypography.subheading())
                    .foregroundStyle(SparkTheme.sunshineYellow)

                Label("\(quest.estimatedMinutes)m", systemImage: "clock")
                    .font(SparkTypography.body())
                    .foregroundStyle(SparkTheme.secondaryText)
            }

            Button {
                HapticsManager.buttonTap()
                onQuestSelected(quest)
            } label: {
                Text("Let's go!")
                    .font(SparkTypography.subheading())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(SparkTheme.mintGreen)
                    )
                    .glow(color: SparkTheme.mintGreen, radius: 8)
            }

            if spinsUsed < maxRespins {
                Button {
                    withAnimation {
                        showResult = false
                        selectedQuest = nil
                    }
                    // M2 fix: Use structured concurrency
                    Task {
                        try? await Task.sleep(for: .milliseconds(300))
                        spin()
                    }
                } label: {
                    Text("Spin again (\(maxRespins - spinsUsed) left)")
                        .font(SparkTypography.caption())
                        .foregroundStyle(SparkTheme.secondaryText)
                }
            }

            Spacer()
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Spin Logic

    private func spin() {
        guard !isSpinning, !quests.isEmpty else { return }

        spinsUsed += 1
        if spinsUsed > maxRespins {
            withAnimation { showNudge = true }
            return
        }

        isSpinning = true
        HapticsManager.buttonTap()

        if reduceMotion {
            // C3 fix: Safe unwrap instead of force unwrap on randomElement()
            guard let picked = quests.randomElement() else { return }
            selectedQuest = picked
            isSpinning = false
            withAnimation { showResult = true }
            HapticsManager.wheelLanding()
            SoundManager.shared.play(.wheelLand)
            return
        }

        // Physics-based spin
        let randomIndex = Int.random(in: 0..<quests.count)
        let segmentAngle = 360.0 / Double(quests.count)
        let targetAngle = 360.0 * Double.random(in: 4...7) + segmentAngle * Double(randomIndex)

        // M2 fix: Use structured concurrency for tick sounds and spin completion
        // Tick sounds during spin
        Task {
            for i in 0..<15 {
                try? await Task.sleep(for: .milliseconds(Int(Double(i) * 120)))
                HapticsManager.wheelTick()
                SoundManager.shared.play(.wheelTick)
            }
        }

        withAnimation(.spring(response: 2.5, dampingFraction: 0.65)) {
            rotation += targetAngle
        }

        Task {
            try? await Task.sleep(for: .milliseconds(2800))
            selectedQuest = quests[randomIndex]
            isSpinning = false
            HapticsManager.wheelLanding()
            SoundManager.shared.play(.wheelLand)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showResult = true
            }
        }
    }
}

// MARK: - Wheel Segment

struct WheelSegment: View {
    let quest: Quest
    let index: Int
    let total: Int

    private var segmentAngle: Double {
        360.0 / Double(total)
    }

    private var startAngle: Double {
        segmentAngle * Double(index)
    }

    private var color: Color {
        SparkTheme.energyColor(for: quest.energyLevel)
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2

            Path { path in
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startAngle - 90),
                    endAngle: .degrees(startAngle + segmentAngle - 90),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color.opacity(index % 2 == 0 ? 0.8 : 0.5))
            .overlay(
                Path { path in
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(startAngle - 90),
                        endAngle: .degrees(startAngle + segmentAngle - 90),
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .stroke(SparkTheme.darkBackground, lineWidth: 2)
            )

            // Quest name label
            let midAngle = startAngle + segmentAngle / 2 - 90
            let labelRadius = radius * 0.6
            let labelX = center.x + labelRadius * cos(midAngle * .pi / 180)
            let labelY = center.y + labelRadius * sin(midAngle * .pi / 180)

            Text(quest.title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: 60)
                .position(x: labelX, y: labelY)
                .rotationEffect(.degrees(midAngle + 90))
        }
    }
}

#Preview {
    SpinWheelView(quests: PreviewSampleData.sampleQuests)
        .modelContainer(PreviewSampleData.container)
}
