import SwiftUI

struct LevelUpCelebrationView: View {
    let newLevel: Int
    var onDismiss: () -> Void = {}

    @State private var showContent = false
    @State private var numberScale: CGFloat = 0.3
    @State private var showConfetti = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            SparkTheme.darkBackground.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(SparkTheme.electricPurple)
                    .glow(color: SparkTheme.electricPurple, radius: 20)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)

                Text("LEVEL UP!")
                    .font(SparkTypography.heading(20))
                    .foregroundStyle(SparkTheme.sunshineYellow)
                    .tracking(4)
                    .opacity(showContent ? 1 : 0)

                Text("\(newLevel)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(SparkTheme.primaryText)
                    .scaleEffect(numberScale)
                    .glow(color: SparkTheme.electricPurple, radius: 15)

                Text("Keep crushing it!")
                    .font(SparkTypography.body())
                    .foregroundStyle(SparkTheme.secondaryText)
                    .opacity(showContent ? 1 : 0)

                Spacer()
            }
        }
        .confetti(isActive: $showConfetti)
        .onAppear {
            HapticsManager.levelUp()
            SoundManager.shared.play(.levelUp)

            if reduceMotion {
                showContent = true
                numberScale = 1
                showConfetti = true
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    showContent = true
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.2)) {
                    numberScale = 1
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    showConfetti = true
                }
            }

            // Auto-dismiss after 3 seconds
            Task {
                try? await Task.sleep(for: .seconds(3))
                dismiss()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level up! You reached level \(newLevel)")
        .accessibilityAddTraits(.isModal)
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            showContent = false
            numberScale = 0.3
        }
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            onDismiss()
        }
    }
}

#Preview {
    LevelUpCelebrationView(newLevel: 5)
}
