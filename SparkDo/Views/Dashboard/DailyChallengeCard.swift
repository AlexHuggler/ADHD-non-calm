import SwiftUI

struct DailyChallengeCard: View {
    let challenge: DailyChallenge
    var onTap: () -> Void = {}

    @State private var appear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: {
            HapticsManager.buttonTap()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(SparkTheme.sunshineYellow)

                    Text("DAILY CHALLENGE")
                        .font(SparkTypography.caption(12))
                        .fontWeight(.bold)
                        .foregroundStyle(SparkTheme.sunshineYellow)
                        .tracking(1.5)

                    Spacer()

                    if challenge.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(SparkTheme.mintGreen)
                            .font(.system(size: 20))
                    } else {
                        Text("3x SPARKS")
                            .font(SparkTypography.caption(11))
                            .fontWeight(.bold)
                            .foregroundStyle(SparkTheme.coral)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(SparkTheme.coral.opacity(0.2))
                            )
                            .accessibilityLabel("Triple sparks bonus")
                    }
                }

                Text(challenge.title)
                    .font(SparkTypography.subheading(18))
                    .foregroundStyle(SparkTheme.primaryText)

                Text(challenge.descriptionText)
                    .font(SparkTypography.body(14))
                    .foregroundStyle(SparkTheme.secondaryText)

                if !challenge.isCompleted {
                    // Progress bar
                    SparkProgressBar(
                        progress: challenge.progress,
                        height: 4,
                        fillStyle: AnyShapeStyle(SparkTheme.sunshineYellow),
                        trackColor: Color.white.opacity(0.1)
                    )

                    Text("\(challenge.currentCount)/\(challenge.targetCount)")
                        .font(SparkTypography.caption(12))
                        .foregroundStyle(SparkTheme.tertiaryText)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                SparkTheme.electricPurple.opacity(0.3),
                                SparkTheme.coral.opacity(0.15),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(SparkTheme.electricPurple.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Daily Challenge: \(challenge.title)")
        .accessibilityHint("Tap to view details")
        .scaleEffect(appear ? 1 : 0.95)
        .opacity(appear ? 1 : 0)
        .onAppear {
            if reduceMotion {
                appear = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    appear = true
                }
            }
        }
    }
}

#Preview {
    DailyChallengeCard(
        challenge: PreviewSampleData.sampleChallenge
    )
    .padding()
    .background(SparkTheme.darkBackground)
    .modelContainer(PreviewSampleData.container)
}
