import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Provider

struct SparkWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SparkWidgetEntry {
        SparkWidgetEntry(date: Date(), todaySparks: 42, streakDays: 5, flameStage: .flame, currentQuestTitle: "Do something awesome")
    }

    func getSnapshot(in context: Context, completion: @escaping (SparkWidgetEntry) -> Void) {
        let entry = SparkWidgetEntry(date: Date(), todaySparks: 42, streakDays: 5, flameStage: .flame, currentQuestTitle: "Do something awesome")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SparkWidgetEntry>) -> Void) {
        let entry = SparkWidgetEntry(
            date: Date(),
            todaySparks: loadTodaySparks(),
            streakDays: loadStreakDays(),
            flameStage: loadFlameStage(),
            currentQuestTitle: loadCurrentQuest()
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Data Loading (reads from App Group UserDefaults)

    private func loadTodaySparks() -> Int {
        WidgetDataProvider.readTodaySparks()
    }

    private func loadStreakDays() -> Int {
        WidgetDataProvider.readStreakDays()
    }

    private func loadFlameStage() -> FlameStage {
        WidgetDataProvider.readFlameStage()
    }

    private func loadCurrentQuest() -> String? {
        WidgetDataProvider.readActiveQuestTitle()
    }
}

// MARK: - Entry

struct SparkWidgetEntry: TimelineEntry {
    let date: Date
    let todaySparks: Int
    let streakDays: Int
    let flameStage: FlameStage
    let currentQuestTitle: String?
}

// MARK: - Small Widget View

struct SparkWidgetSmallView: View {
    let entry: SparkWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Color(hex: 0xFECA57))
                Text("\(entry.todaySparks)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text("Sparks today")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: 0xFF6B6B))
                Text("\(entry.streakDays)d")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(hex: 0x1A1A2E)
        }
    }
}

// MARK: - Medium Widget View

struct SparkWidgetMediumView: View {
    let entry: SparkWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Sparks + Streak
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color(hex: 0xFECA57))
                    Text("\(entry.todaySparks)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: 0xFF6B6B))
                    Text("\(entry.streakDays) day streak")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Divider()
                .background(.white.opacity(0.2))

            // Right: Current quest or spin prompt
            VStack(alignment: .leading, spacing: 6) {
                if let quest = entry.currentQuestTitle {
                    Text("Current Quest")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)

                    Text(quest)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                } else {
                    Image(systemName: "circle.dotted")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: 0xFF6B6B))

                    Text("Tap to spin!")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(hex: 0x1A1A2E)
        }
    }
}

// MARK: - Widget Definition

struct SparkWidget: Widget {
    let kind: String = "SparkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SparkWidgetProvider()) { entry in
            switch entry.date {
            default:
                SparkWidgetSmallView(entry: entry)
            }
        }
        .configurationDisplayName("Spark Counter")
        .description("See your daily Sparks and streak at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
