import SwiftUI

struct ProgressMapView: View {
    let profile: PlayerProfile

    @State private var animatePosition = false

    private var milestones: [Milestone] {
        (1...max(profile.level + 3, 5)).map { level in
            Milestone(
                level: level,
                sparksRequired: PlayerProfile.sparksRequired(forLevel: level),
                isReached: level <= profile.level,
                isCurrent: level == profile.level
            )
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(milestones.reversed().enumerated()), id: \.element.level) { index, milestone in
                        MilestoneNode(
                            milestone: milestone,
                            isLast: index == milestones.count - 1,
                            animatePosition: animatePosition
                        )
                        .id(milestone.level)
                    }
                }
                .padding()
            }
            .task {
                withAnimation(.easeOut(duration: 0.5)) {
                    animatePosition = true
                }
                // M2 fix: Use structured concurrency instead of DispatchQueue
                try? await Task.sleep(for: .milliseconds(100))
                proxy.scrollTo(profile.level, anchor: .center)
            }
        }
        .background(SparkTheme.darkBackground)
        .navigationTitle("Journey Map")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct Milestone: Identifiable {
    let level: Int
    let sparksRequired: Int
    let isReached: Bool
    let isCurrent: Bool
    var id: Int { level }
}

struct MilestoneNode: View {
    let milestone: Milestone
    let isLast: Bool
    let animatePosition: Bool

    @State private var glow = false
    // H6 fix: Check reduce-motion before running glow animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 16) {
            // Path line and node
            VStack(spacing: 0) {
                if !isLast {
                    Rectangle()
                        .fill(milestone.isReached ? SparkTheme.electricPurple : SparkTheme.cardBackground)
                        .frame(width: 3, height: 30)
                }

                ZStack {
                    Circle()
                        .fill(nodeColor)
                        .frame(width: milestone.isCurrent ? 40 : 28, height: milestone.isCurrent ? 40 : 28)

                    if milestone.isCurrent && !reduceMotion {
                        Circle()
                            .fill(SparkTheme.electricPurple.opacity(0.3))
                            .frame(width: 52, height: 52)
                            .scaleEffect(glow ? 1.2 : 1.0)
                            .opacity(glow ? 0.3 : 0.6)
                            .animation(
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: glow
                            )
                    }

                    if milestone.isReached {
                        Image(systemName: milestone.isCurrent ? "star.fill" : "checkmark")
                            .font(.system(size: milestone.isCurrent ? 16 : 12, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(milestone.level)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(SparkTheme.tertiaryText)
                    }
                }

                Rectangle()
                    .fill(milestone.isReached ? SparkTheme.electricPurple : SparkTheme.cardBackground)
                    .frame(width: 3, height: 30)
            }

            // Milestone info
            VStack(alignment: .leading, spacing: 4) {
                Text("Level \(milestone.level)")
                    .font(SparkTypography.subheading(milestone.isCurrent ? 18 : 15))
                    .foregroundStyle(milestone.isReached ? SparkTheme.primaryText : SparkTheme.tertiaryText)

                if milestone.isReached && !milestone.isCurrent {
                    Text("Reached!")
                        .font(SparkTypography.caption(12))
                        .foregroundStyle(SparkTheme.mintGreen)
                } else if !milestone.isReached {
                    Text("\(milestone.sparksRequired) Sparks needed")
                        .font(SparkTypography.caption(12))
                        .foregroundStyle(SparkTheme.tertiaryText)
                } else {
                    Text("You are here")
                        .font(SparkTypography.caption(12))
                        .foregroundStyle(SparkTheme.sunshineYellow)
                }
            }

            Spacer()
        }
        .opacity(animatePosition ? 1 : 0)
        .offset(x: animatePosition ? 0 : -20)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7)
                .delay(Double(milestone.level) * 0.05),
            value: animatePosition
        )
        .onAppear { glow = true }
    }

    private var nodeColor: Color {
        if milestone.isCurrent { return SparkTheme.electricPurple }
        if milestone.isReached { return SparkTheme.mintGreen }
        return SparkTheme.cardBackground
    }
}

#Preview {
    NavigationStack {
        ProgressMapView(profile: PreviewSampleData.sampleProfile)
    }
    .modelContainer(PreviewSampleData.container)
}
