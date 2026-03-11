import SwiftUI

struct QuestCardView: View {
    let quest: Quest
    var onComplete: () -> Void = {}
    var onSkip: () -> Void = {}
    var onTap: () -> Void = {}

    @State private var offset: CGFloat = 0
    @State private var bobPhase: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cardColors: [Color] = [
        SparkTheme.electricPurple,
        SparkTheme.teal,
        SparkTheme.coral,
        SparkTheme.mintGreen,
        SparkTheme.sunshineYellow,
    ]

    private var accentColor: Color {
        SparkTheme.energyColor(for: quest.energyLevel)
    }

    var body: some View {
        ZStack {
            // Swipe indicators
            HStack {
                // Complete indicator (right swipe)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(SparkTheme.mintGreen)
                    .opacity(offset > 50 ? 1 : 0)

                Spacer()

                // Skip indicator (left swipe)
                Image(systemName: "forward.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(SparkTheme.tertiaryText)
                    .opacity(offset < -50 ? 1 : 0)
            }
            .padding(.horizontal, 20)

            // Card content
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Energy indicator bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor)
                        .frame(width: 4, height: 44)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(quest.title)
                            .font(SparkTypography.questCard())
                            .foregroundStyle(SparkTheme.primaryText)
                            .lineLimit(2)

                        HStack(spacing: 12) {
                            // XP value
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(SparkTheme.sunshineYellow)

                                Text("\(quest.xpValue) XP")
                                    .font(SparkTypography.caption(12))
                                    .foregroundStyle(SparkTheme.sunshineYellow)
                            }

                            // Estimated time
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 11))
                                    .foregroundStyle(SparkTheme.tertiaryText)

                                Text("\(quest.estimatedMinutes)m")
                                    .font(SparkTypography.caption(12))
                                    .foregroundStyle(SparkTheme.tertiaryText)
                            }

                            // Energy tag
                            Text(quest.energyLevel.label)
                                .font(SparkTypography.caption(11))
                                .foregroundStyle(accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(accentColor.opacity(0.15))
                                )
                        }
                    }

                    Spacer()

                    if quest.isEpic {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(SparkTheme.sunshineYellow)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(SparkTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(accentColor.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .offset(x: offset)
            .offset(y: reduceMotion ? 0 : (bobPhase ? -1.5 : 1.5))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation.width
                    }
                    // M2 fix: Use structured concurrency instead of DispatchQueue.main.asyncAfter
                    .onEnded { value in
                        if value.translation.width > 100 {
                            // Swipe right — complete
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = 400
                            }
                            HapticsManager.questComplete()
                            SoundManager.shared.play(.questComplete)
                            Task {
                                try? await Task.sleep(for: .milliseconds(300))
                                onComplete()
                            }
                        } else if value.translation.width < -100 {
                            // Swipe left — skip
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = -400
                            }
                            Task {
                                try? await Task.sleep(for: .milliseconds(300))
                                onSkip()
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: Double.random(in: 2.0...3.0))
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...1))
            ) {
                bobPhase = true
            }
        }
    }
}
