import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil
    var iconColor: Color = SparkTheme.tertiaryText
    var action: (() -> Void)? = nil
    var actionLabel: String = "Get Started"

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(iconColor)

            Text(title)
                .font(SparkTypography.heading(24))
                .foregroundStyle(SparkTheme.primaryText)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(SparkTypography.body())
                    .foregroundStyle(SparkTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let action {
                Button {
                    HapticsManager.buttonTap()
                    action()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionLabel)
                    }
                    .font(SparkTypography.subheading())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(SparkTheme.electricPurple)
                    )
                    .glow(color: SparkTheme.electricPurple, radius: 8)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ZStack {
        SparkTheme.darkBackground.ignoresSafeArea()

        VStack(spacing: 40) {
            EmptyStateView(
                icon: "trophy.fill",
                title: "Quest board is clear!",
                message: "You're a legend.\nTime to capture new adventures.",
                iconColor: SparkTheme.sunshineYellow,
                action: {},
                actionLabel: "Add a Quest"
            )

            EmptyStateView(
                icon: "lock",
                title: "All achievements unlocked!"
            )
        }
    }
}
