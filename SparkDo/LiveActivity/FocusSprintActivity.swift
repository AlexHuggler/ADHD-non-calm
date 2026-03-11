import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Activity Attributes

struct FocusSprintAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: Int
        var sparkBonus: Int
    }

    var questTitle: String
    var totalDuration: Int
}

// MARK: - Live Activity Widget

struct FocusSprintLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSprintAttributes.self) { context in
            // Lock Screen / Notification banner
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: 0xFECA57))
                        Text("+\(context.state.sparkBonus)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: 0xFECA57))
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerString(context.state.timeRemaining))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.questTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // Progress bar
                    let total = context.attributes.totalDuration
                    let remaining = context.state.timeRemaining
                    let progress = total > 0 ? CGFloat(total - remaining) / CGFloat(total) : 0

                    VStack(spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.2))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(Color(hex: 0x6C5CE7))
                                    .frame(width: geo.size.width * progress, height: 4)
                            }
                        }
                        .frame(height: 4)

                        Text("Sprint in progress")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            } compactLeading: {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0xFECA57))
            } compactTrailing: {
                Text(timerString(context.state.timeRemaining))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0xFECA57))
            }
        }
    }

    // MARK: - Lock Screen View

    private func lockScreenView(context: ActivityViewContext<FocusSprintAttributes>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.questTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0xFECA57))
                    Text("+\(context.state.sparkBonus) Sparks")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: 0xFECA57))
                }
            }

            Spacer()

            Text(timerString(context.state.timeRemaining))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding()
        .activityBackgroundTint(Color(hex: 0x1A1A2E))
    }

    // MARK: - Helpers

    private func timerString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Activity Manager

@Observable
final class FocusSprintActivityManager {
    private var currentActivity: Activity<FocusSprintAttributes>?

    func startActivity(questTitle: String, durationMinutes: Int, sparkBonus: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = FocusSprintAttributes(
            questTitle: questTitle,
            totalDuration: durationMinutes * 60
        )

        let state = FocusSprintAttributes.ContentState(
            timeRemaining: durationMinutes * 60,
            sparkBonus: sparkBonus
        )

        // M1 fix: Log errors instead of silent catch
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
        } catch {
            print("SparkDo [FocusSprintActivityManager]: Failed to start Live Activity: \(error)")
        }
    }

    func updateActivity(timeRemaining: Int, sparkBonus: Int) {
        let state = FocusSprintAttributes.ContentState(
            timeRemaining: timeRemaining,
            sparkBonus: sparkBonus
        )

        Task {
            await currentActivity?.update(.init(state: state, staleDate: nil))
        }
    }

    func endActivity() {
        let finalState = FocusSprintAttributes.ContentState(
            timeRemaining: 0,
            sparkBonus: 0
        )

        Task {
            await currentActivity?.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}
