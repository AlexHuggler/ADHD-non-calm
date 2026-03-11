import SwiftUI

struct SettingsView: View {
    @Bindable var profile: PlayerProfile
    @State private var showPaywall = false

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Level \(profile.level)")
                            .font(SparkTypography.subheading())
                            .foregroundStyle(SparkTheme.primaryText)

                        Text("\(profile.totalSparks) total Sparks earned")
                            .font(SparkTypography.caption())
                            .foregroundStyle(SparkTheme.secondaryText)
                    }

                    Spacer()

                    if profile.isPremium {
                        Text("PREMIUM")
                            .font(SparkTypography.caption(11))
                            .fontWeight(.bold)
                            .foregroundStyle(SparkTheme.sunshineYellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(SparkTheme.sunshineYellow.opacity(0.2))
                            )
                    }
                }
                .listRowBackground(SparkTheme.cardBackground)
            }

            Section("Feedback") {
                Toggle(isOn: $profile.soundEnabled) {
                    Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                }
                .onChange(of: profile.soundEnabled) { _, newValue in
                    SoundManager.shared.isEnabled = newValue
                    if newValue {
                        SoundManager.shared.play(.sparkEarned)
                    }
                }

                Toggle(isOn: $profile.hapticsEnabled) {
                    Label("Haptics", systemImage: "hand.tap.fill")
                }
                .onChange(of: profile.hapticsEnabled) { _, newValue in
                    HapticsManager.isEnabled = newValue
                    if newValue {
                        HapticsManager.buttonTap()
                    }
                }
            }
            .listRowBackground(SparkTheme.cardBackground)

            if !profile.isPremium {
                Section {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(SparkTheme.sunshineYellow)

                            Text("Upgrade to Premium")
                                .font(SparkTypography.body())
                                .foregroundStyle(SparkTheme.primaryText)

                            Spacer()

                            Text("$9.99")
                                .font(SparkTypography.caption())
                                .foregroundStyle(SparkTheme.sunshineYellow)
                        }
                    }
                }
                .listRowBackground(SparkTheme.cardBackground)
            }

            Section("Stats") {
                StatRow(label: "Quests Completed", value: "\(profile.questsCompleted)")
                StatRow(label: "Sprints Completed", value: "\(profile.sprintsCompleted)")
                StatRow(label: "Focus Minutes", value: "\(profile.totalFocusMinutes)")
                StatRow(label: "Member Since", value: profile.joinDate.formatted(date: .abbreviated, time: .omitted))
            }
            .listRowBackground(SparkTheme.cardBackground)

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(SparkTheme.tertiaryText)
                }

                HStack {
                    Text("Made with")
                    Spacer()
                    Text("SwiftUI + SwiftData")
                        .foregroundStyle(SparkTheme.tertiaryText)
                }
            }
            .listRowBackground(SparkTheme.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(SparkTheme.darkBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .foregroundStyle(SparkTheme.primaryText)
        .tint(SparkTheme.electricPurple)
        .sheet(isPresented: $showPaywall) {
            PaywallView(profile: profile)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(SparkTheme.secondaryText)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(profile: PreviewSampleData.sampleProfile)
    }
    .modelContainer(PreviewSampleData.container)
}
