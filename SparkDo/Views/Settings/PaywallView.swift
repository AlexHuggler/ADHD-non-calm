import SwiftUI

struct PaywallView: View {
    @Bindable var profile: PlayerProfile
    @State private var storeKit = StoreKitManager()
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss

    private let features: [(String, String, String)] = [
        ("bolt.fill", "Unlimited Sprints", "No daily limit on focus sprints"),
        ("waveform.path.ecg", "Live Activity", "Timer on Lock Screen & Dynamic Island"),
        ("bag.fill", "Power-Up Shop", "Full cosmetic catalog access"),
        ("chart.bar.fill", "Weekly Recap", "Animated weekly summary stories"),
        ("link", "Quest Chains", "Create multi-step quest sequences"),
        ("icloud.fill", "iCloud Sync", "Sync across all your devices"),
        ("trophy.fill", "Achievements", "Full achievement system"),
        ("paintpalette.fill", "Custom Themes", "Customize card colors & app themes"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                SparkTheme.darkBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 48))
                                .foregroundStyle(SparkTheme.sunshineYellow)
                                .pulseGlow(color: SparkTheme.sunshineYellow)

                            Text("SparkDo Premium")
                                .font(SparkTypography.heading(28))
                                .foregroundStyle(SparkTheme.primaryText)

                            Text("Unlock the full power of SparkDo")
                                .font(SparkTypography.body())
                                .foregroundStyle(SparkTheme.secondaryText)
                        }
                        .padding(.top, 20)

                        // Features
                        VStack(spacing: 0) {
                            ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                                HStack(spacing: 14) {
                                    Image(systemName: feature.0)
                                        .font(.system(size: 18))
                                        .foregroundStyle(SparkTheme.electricPurple)
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(feature.1)
                                            .font(SparkTypography.body())
                                            .foregroundStyle(SparkTheme.primaryText)

                                        Text(feature.2)
                                            .font(SparkTypography.caption(12))
                                            .foregroundStyle(SparkTheme.tertiaryText)
                                    }

                                    Spacer()

                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(SparkTheme.mintGreen)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)

                                if feature.0 != features.last?.0 {
                                    Divider()
                                        .background(SparkTheme.cardBackground)
                                        .padding(.leading, 62)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(SparkTheme.surfaceBackground)
                        )
                        .padding(.horizontal)

                        // Price & Purchase
                        VStack(spacing: 12) {
                            Button {
                                purchasePremium()
                            } label: {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Unlock for $9.99")
                                            .font(SparkTypography.subheading())
                                    }
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(SparkTheme.electricPurple)
                                )
                                .glow(color: SparkTheme.electricPurple, radius: 10)
                            }
                            .disabled(isPurchasing)
                            .padding(.horizontal)

                            Text("One-time purchase. No subscriptions.")
                                .font(SparkTypography.caption(12))
                                .foregroundStyle(SparkTheme.tertiaryText)

                            Button("Restore Purchase") {
                                restorePurchase()
                            }
                            .font(SparkTypography.caption())
                            .foregroundStyle(SparkTheme.teal)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(SparkTheme.secondaryText)
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Purchase

    private func purchasePremium() {
        isPurchasing = true
        Task {
            do {
                let success = try await storeKit.purchase()
                if success {
                    profile.isPremium = true
                    HapticsManager.levelUp()
                    SoundManager.shared.play(.levelUp)
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isPurchasing = false
        }
    }

    private func restorePurchase() {
        Task {
            await storeKit.restore()
            if storeKit.isPurchased {
                profile.isPremium = true
                dismiss()
            }
        }
    }
}
