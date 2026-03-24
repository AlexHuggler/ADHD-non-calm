import SwiftUI

struct StreakFlameView: View {
    let streak: Streak
    @State private var showDetail = false
    @State private var flicker = false
    @State private var showMilestone = false
    // H5 fix: Check reduce-motion preference before running flicker animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let milestones: Set<Int> = [7, 14, 30, 60, 100]

    private var milestoneTitle: String {
        switch streak.currentDays {
        case 7: "1 Week Warrior!"
        case 14: "2 Week Champion!"
        case 30: "Monthly Master!"
        case 60: "60-Day Legend!"
        case 100: "Century Streak!"
        default: "Streak Milestone!"
        }
    }

    var body: some View {
        Button {
            showDetail = true
            HapticsManager.buttonTap()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24 * streak.flameStage.flameScale))
                    .foregroundStyle(flameGradient)
                    .scaleEffect(flicker && !reduceMotion ? 1.05 : 1.0)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: flicker
                    )
                    // H7 fix: Accessibility label for flame icon
                    .accessibilityLabel("Streak flame, \(streak.flameStage.label)")

                VStack(alignment: .leading, spacing: 2) {
                    Text(streak.flameStage.label)
                        .font(SparkTypography.caption(13))
                        .fontWeight(.semibold)
                        .foregroundStyle(SparkTheme.primaryText)

                    Text("\(streak.currentDays) day streak")
                        .font(SparkTypography.caption(11))
                        .foregroundStyle(SparkTheme.secondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SparkTheme.cardBackground)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            flicker = true
            // Check for milestone celebration
            if Self.milestones.contains(streak.currentDays) {
                let key = "streakMilestone_\(streak.currentDays)"
                if !UserDefaults.standard.bool(forKey: key) {
                    UserDefaults.standard.set(true, forKey: key)
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            showMilestone = true
                        }
                        HapticsManager.streakRecord()
                    }
                }
            }
        }
        .overlay {
            if showMilestone {
                StreakMilestoneCelebration(
                    days: streak.currentDays,
                    title: milestoneTitle,
                    flameStage: streak.flameStage
                ) {
                    withAnimation { showMilestone = false }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showDetail) {
            StreakDetailSheet(streak: streak)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var flameGradient: LinearGradient {
        switch streak.flameStage {
        case .ember:
            LinearGradient(colors: [.gray, .orange.opacity(0.5)], startPoint: .bottom, endPoint: .top)
        case .spark:
            LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top)
        case .flame:
            LinearGradient(colors: [.red, .orange, .yellow], startPoint: .bottom, endPoint: .top)
        case .blaze:
            LinearGradient(colors: [.red, .orange, SparkTheme.sunshineYellow], startPoint: .bottom, endPoint: .top)
        case .inferno:
            LinearGradient(colors: [SparkTheme.coral, .orange, SparkTheme.sunshineYellow, .white], startPoint: .bottom, endPoint: .top)
        case .supernova:
            LinearGradient(colors: [SparkTheme.electricPurple, SparkTheme.coral, SparkTheme.sunshineYellow, .white], startPoint: .bottom, endPoint: .top)
        }
    }
}

// MARK: - Detail Sheet

struct StreakDetailSheet: View {
    let streak: Streak

    var body: some View {
        VStack(spacing: 24) {
            Text("Streak Details")
                .font(SparkTypography.heading(24))
                .foregroundStyle(SparkTheme.primaryText)

            // Flame display
            Image(systemName: "flame.fill")
                .font(.system(size: 60 * streak.flameStage.flameScale))
                .foregroundStyle(SparkTheme.coral)
                .pulseGlow(color: SparkTheme.coral)

            VStack(spacing: 8) {
                Text("\(streak.currentDays) Days")
                    .font(SparkTypography.heading(32))
                    .foregroundStyle(SparkTheme.primaryText)

                Text(streak.flameStage.label)
                    .font(SparkTypography.subheading())
                    .foregroundStyle(SparkTheme.secondaryText)
            }

            // Shield status
            HStack(spacing: 16) {
                ForEach(0..<2, id: \.self) { index in
                    VStack(spacing: 4) {
                        Image(systemName: index < streak.shieldDaysRemaining ? "shield.fill" : "shield")
                            .font(.system(size: 28))
                            .foregroundStyle(
                                index < streak.shieldDaysRemaining
                                    ? SparkTheme.teal
                                    : SparkTheme.tertiaryText
                            )

                        Text("Shield")
                            .font(SparkTypography.caption(11))
                            .foregroundStyle(SparkTheme.tertiaryText)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SparkTheme.surfaceBackground)
            )

            Text("Shields protect your streak on days you miss. They reset every Monday.")
                .font(SparkTypography.caption(12))
                .foregroundStyle(SparkTheme.tertiaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if streak.longestStreak > 0 {
                Text("Longest streak: \(streak.longestStreak) days")
                    .font(SparkTypography.caption())
                    .foregroundStyle(SparkTheme.secondaryText)
            }

            Spacer()
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity)
        .background(SparkTheme.darkBackground)
    }
}

// MARK: - Streak Milestone Celebration

struct StreakMilestoneCelebration: View {
    let days: Int
    let title: String
    let flameStage: FlameStage
    var onDismiss: () -> Void = {}

    @State private var appear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 64 * flameStage.flameScale))
                    .foregroundStyle(SparkTheme.coral)
                    .pulseGlow(color: SparkTheme.coral)
                    .scaleEffect(appear ? 1 : 0.3)

                Text(title)
                    .font(SparkTypography.heading(28))
                    .foregroundStyle(SparkTheme.primaryText)

                Text("\(days) days and counting!")
                    .font(SparkTypography.body())
                    .foregroundStyle(SparkTheme.secondaryText)

                Button {
                    onDismiss()
                } label: {
                    Text("Keep the fire alive!")
                        .font(SparkTypography.subheading())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(SparkTheme.coral)
                        )
                        .glow(color: SparkTheme.coral, radius: 8)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isModal)
        }
        .onAppear {
            if reduceMotion {
                appear = true
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    appear = true
                }
            }
            // Auto-dismiss after 5 seconds
            Task {
                try? await Task.sleep(for: .seconds(5))
                onDismiss()
            }
        }
    }
}

#Preview {
    StreakFlameView(streak: PreviewSampleData.sampleStreak)
        .padding()
        .background(SparkTheme.darkBackground)
        .modelContainer(PreviewSampleData.container)
}
