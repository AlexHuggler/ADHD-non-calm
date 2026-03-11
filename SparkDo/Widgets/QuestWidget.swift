import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct QuestWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuestWidgetEntry {
        QuestWidgetEntry(date: Date(), questTitle: "Complete the report", xpValue: 50, energyLevel: .medium)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuestWidgetEntry) -> Void) {
        let entry = QuestWidgetEntry(date: Date(), questTitle: "Complete the report", xpValue: 50, energyLevel: .medium)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuestWidgetEntry>) -> Void) {
        // Load current active quest from shared container
        let entry = QuestWidgetEntry(
            date: Date(),
            questTitle: loadActiveQuestTitle(),
            xpValue: loadActiveQuestXP(),
            energyLevel: loadActiveQuestEnergy()
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadActiveQuestTitle() -> String? { nil }
    private func loadActiveQuestXP() -> Int { 0 }
    private func loadActiveQuestEnergy() -> EnergyLevel { .medium }
}

// MARK: - Entry

struct QuestWidgetEntry: TimelineEntry {
    let date: Date
    let questTitle: String?
    let xpValue: Int
    let energyLevel: EnergyLevel
}

// MARK: - Widget View

struct QuestWidgetView: View {
    let entry: QuestWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ACTIVE QUEST")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(1)

                Spacer()
            }

            if let title = entry.questTitle {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Spacer()

                HStack {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: 0xFECA57))
                        Text("\(entry.xpValue) XP")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: 0xFECA57))
                    }

                    Spacer()

                    energyDot
                }
            } else {
                Spacer()

                VStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: 0x54A0FF))

                    Text("No active quest")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(hex: 0x1A1A2E)
        }
    }

    private var energyDot: some View {
        let color: Color = switch entry.energyLevel {
        case .low: Color(hex: 0x5CD859)
        case .medium: Color(hex: 0xFECA57)
        case .high: Color(hex: 0xFF6B6B)
        }

        return Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

// MARK: - Widget Definition

struct QuestWidget: Widget {
    let kind: String = "QuestWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuestWidgetProvider()) { entry in
            QuestWidgetView(entry: entry)
        }
        .configurationDisplayName("Current Quest")
        .description("See your active quest at a glance.")
        .supportedFamilies([.systemSmall])
    }
}
