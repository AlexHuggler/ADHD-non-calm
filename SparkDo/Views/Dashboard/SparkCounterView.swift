import SwiftUI

struct SparkCounterView: View {
    let totalSparks: Int
    let todaySparks: Int
    let level: Int
    let levelProgress: Double

    @State private var displayedSparks: Int = 0
    @State private var animateGlow = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(SparkTheme.sunshineYellow)
                    .pulseGlow(color: SparkTheme.sunshineYellow)
                    .accessibilityHidden(true)

                Text("\(displayedSparks)")
                    .font(SparkTypography.heading(36))
                    .foregroundStyle(SparkTheme.primaryText)
                    .contentTransition(.numericText())
            }

            Text("+\(todaySparks) today")
                .font(SparkTypography.caption())
                .foregroundStyle(SparkTheme.secondaryText)

            // Level badge
            HStack(spacing: 6) {
                Text("LVL \(level)")
                    .font(SparkTypography.caption(14))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(SparkTheme.electricPurple)
                    )
                    .glow(color: SparkTheme.electricPurple, radius: 6)

                // Progress to next level
                SparkProgressBar(progress: levelProgress)
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(level), \(displayedSparks) total sparks, plus \(todaySparks) today")
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SparkTheme.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SparkTheme.electricPurple.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                displayedSparks = totalSparks
            }
        }
        .onChange(of: totalSparks) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                displayedSparks = newValue
            }
        }
    }
}

#Preview {
    SparkCounterView(
        totalSparks: 1250,
        todaySparks: 45,
        level: 5,
        levelProgress: 0.6
    )
    .padding()
    .background(SparkTheme.darkBackground)
}
