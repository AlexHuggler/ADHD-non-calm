import SwiftUI

struct QuestTimerView: View {
    let quest: Quest
    let sparkEngine: SparkEngine
    @Bindable var profile: PlayerProfile

    var onComplete: () -> Void = {}
    var onCancel: () -> Void = {}

    @State private var selectedDuration: Int = 15
    @State private var timeRemaining: Int = 0
    @State private var isRunning = false
    @State private var isCompleted = false
    @State private var showConfetti = false
    @State private var timer: Timer?
    @State private var pulseScale: CGFloat = 1.0
    @State private var showDurationPicker = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let durations = [5, 10, 15, 25]

    var body: some View {
        ZStack {
            SparkTheme.darkBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                HStack {
                    Button("Cancel") {
                        stopTimer()
                        onCancel()
                    }
                    .foregroundStyle(SparkTheme.secondaryText)

                    Spacer()

                    Text("Focus Sprint")
                        .font(SparkTypography.subheading())
                        .foregroundStyle(SparkTheme.primaryText)

                    Spacer()

                    Color.clear.frame(width: 60)
                }
                .padding(.horizontal)

                Spacer()

                if isCompleted {
                    completionView
                } else if showDurationPicker {
                    durationPickerView
                } else {
                    timerView
                }

                Spacer()
            }
        }
        .confetti(isActive: $showConfetti)
        .onDisappear {
            // C2 fix: Ensure timer is invalidated when view is dismissed to prevent
            // leaked timer firing into deallocated state.
            stopTimer()
        }
    }

    // MARK: - Duration Picker

    private var durationPickerView: some View {
        VStack(spacing: 24) {
            Text(quest.title)
                .font(SparkTypography.heading(22))
                .foregroundStyle(SparkTheme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Choose your sprint duration")
                .font(SparkTypography.body())
                .foregroundStyle(SparkTheme.secondaryText)

            HStack(spacing: 12) {
                ForEach(durations, id: \.self) { duration in
                    Button {
                        selectedDuration = duration
                        HapticsManager.buttonTap()
                    } label: {
                        Text("\(duration)m")
                            .font(SparkTypography.subheading())
                            .foregroundStyle(selectedDuration == duration ? .white : SparkTheme.secondaryText)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedDuration == duration
                                        ? SparkTheme.electricPurple
                                        : SparkTheme.cardBackground)
                            )
                    }
                }
            }

            // Spark bonus preview
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(SparkTheme.sunshineYellow)
                Text("\(quest.xpValue * 2) Sparks (2x sprint bonus)")
                    .font(SparkTypography.caption())
                    .foregroundStyle(SparkTheme.sunshineYellow)
            }

            Button {
                startTimer()
                HapticsManager.buttonTap()
            } label: {
                Text("Start Sprint")
                    .font(SparkTypography.subheading())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(SparkTheme.electricPurple)
                    )
                    .glow(color: SparkTheme.electricPurple, radius: 10)
            }
        }
    }

    // MARK: - Timer Display

    private var timerView: some View {
        VStack(spacing: 24) {
            Text(quest.title)
                .font(SparkTypography.subheading(16))
                .foregroundStyle(SparkTheme.secondaryText)

            // H9 fix: Use GeometryReader for responsive timer sizing
            GeometryReader { geo in
                let timerSize = min(geo.size.width, geo.size.height) * 0.65
                ZStack {
                    Circle()
                        .stroke(SparkTheme.cardBackground, lineWidth: 8)
                        .frame(width: timerSize, height: timerSize)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            SparkTheme.primaryGradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: timerSize, height: timerSize)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)

                    VStack(spacing: 4) {
                        Text(timeString)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(SparkTheme.primaryText)
                            .monospacedDigit()
                            .accessibilityLabel("Time remaining: \(timeString)")

                        Text("remaining")
                            .font(SparkTypography.caption())
                            .foregroundStyle(SparkTheme.tertiaryText)
                    }

                    if !reduceMotion {
                        Circle()
                            .fill(SparkTheme.electricPurple.opacity(0.1))
                            .frame(width: timerSize + 20, height: timerSize + 20)
                            .scaleEffect(pulseScale)
                            .animation(
                                .easeInOut(duration: 2).repeatForever(autoreverses: true),
                                value: pulseScale
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { pulseScale = 1.1 }
            }
            .aspectRatio(1, contentMode: .fit)

            // Spark bonus display
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(SparkTheme.sunshineYellow)
                Text("+\(quest.xpValue * 2) Sparks on completion")
                    .font(SparkTypography.caption())
                    .foregroundStyle(SparkTheme.sunshineYellow)
            }
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundStyle(SparkTheme.sunshineYellow)
                .pulseGlow(color: SparkTheme.sunshineYellow)

            Text("Sprint Complete!")
                .font(SparkTypography.heading(28))
                .foregroundStyle(SparkTheme.primaryText)

            Text(quest.title)
                .font(SparkTypography.body())
                .foregroundStyle(SparkTheme.secondaryText)

            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(SparkTheme.sunshineYellow)
                Text("+\(quest.xpValue * 2) Sparks earned!")
                    .font(SparkTypography.subheading())
                    .foregroundStyle(SparkTheme.sunshineYellow)
            }
            .shimmer(color: SparkTheme.sunshineYellow)

            VStack(spacing: 12) {
                Button {
                    HapticsManager.buttonTap()
                    onComplete()
                } label: {
                    Text("Done!")
                        .font(SparkTypography.subheading())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(SparkTheme.mintGreen)
                        )
                }

                Button {
                    // Keep going — reset timer
                    HapticsManager.buttonTap()
                    isCompleted = false
                    showDurationPicker = true
                } label: {
                    Text("Keep going?")
                        .font(SparkTypography.caption())
                        .foregroundStyle(SparkTheme.teal)
                }
            }
        }
    }

    // MARK: - Timer Logic

    private var progress: CGFloat {
        let total = selectedDuration * 60
        guard total > 0 else { return 0 }
        return CGFloat(total - timeRemaining) / CGFloat(total)
    }

    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startTimer() {
        showDurationPicker = false
        timeRemaining = selectedDuration * 60
        isRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completeSprintTimer()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func completeSprintTimer() {
        stopTimer()

        // Award sparks
        let _ = sparkEngine.completeQuest(quest, wasSprint: true, profile: profile)
        profile.sprintsCompleted += 1
        profile.totalFocusMinutes += selectedDuration
        profile.dailySprintsUsed += 1

        // Celebration
        isCompleted = true
        showConfetti = true
        HapticsManager.levelUp()
        SoundManager.shared.play(.sprintComplete)
    }
}
