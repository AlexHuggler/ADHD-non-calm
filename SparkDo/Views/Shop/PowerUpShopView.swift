import SwiftUI
import SwiftData

struct PowerUpShopView: View {
    @Query private var powerUps: [PowerUp]
    @Bindable var profile: PlayerProfile
    var sparkEngine: SparkEngine

    @State private var selectedCategory: PowerUpCategory = .theme
    @State private var showPurchaseConfirm = false
    @State private var selectedPowerUp: PowerUp?
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 0) {
            // Spendable sparks header
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(SparkTheme.sunshineYellow)
                Text("\(profile.spendableSparks) Sparks available")
                    .font(SparkTypography.subheading())
                    .foregroundStyle(SparkTheme.primaryText)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(SparkTheme.surfaceBackground)

            // Category picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PowerUpCategory.allCases, id: \.rawValue) { category in
                        Button {
                            selectedCategory = category
                            HapticsManager.buttonTap()
                        } label: {
                            Text(category.label)
                                .font(SparkTypography.caption(14))
                                .foregroundStyle(
                                    selectedCategory == category ? .white : SparkTheme.secondaryText
                                )
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(
                                            selectedCategory == category
                                                ? SparkTheme.electricPurple
                                                : SparkTheme.cardBackground
                                        )
                                )
                        }
                    }
                }
                .padding()
            }

            // Power-ups grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(filteredPowerUps) { powerUp in
                        PowerUpCard(powerUp: powerUp, canAfford: profile.spendableSparks >= powerUp.sparkCost) {
                            selectedPowerUp = powerUp
                            showPurchaseConfirm = true
                        }
                    }
                }
                .padding()
            }
        }
        .background(SparkTheme.darkBackground)
        .navigationTitle("Power-Up Shop")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confetti(isActive: $showConfetti)
        .alert("Purchase Power-Up?", isPresented: $showPurchaseConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Buy for \(selectedPowerUp?.sparkCost ?? 0) Sparks") {
                if let powerUp = selectedPowerUp {
                    purchasePowerUp(powerUp)
                }
            }
        } message: {
            if let powerUp = selectedPowerUp {
                Text("\(powerUp.name) — \(powerUp.descriptionText)")
            }
        }
    }

    private var filteredPowerUps: [PowerUp] {
        powerUps.filter { $0.category == selectedCategory }
    }

    private func purchasePowerUp(_ powerUp: PowerUp) {
        guard sparkEngine.spendSparks(powerUp.sparkCost, profile: profile) else {
            HapticsManager.error()
            return
        }

        powerUp.isPurchased = true
        HapticsManager.questComplete()
        SoundManager.shared.play(.achievementUnlock)
        showConfetti = true
    }
}

// MARK: - Power-Up Card

struct PowerUpCard: View {
    let powerUp: PowerUp
    let canAfford: Bool
    let onPurchase: () -> Void

    var body: some View {
        Button(action: {
            guard !powerUp.isPurchased && canAfford else { return }
            onPurchase()
        }) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            powerUp.colorHex != nil
                                ? Color(hex: UInt(powerUp.colorHex!.dropFirst(), radix: 16) ?? 0).opacity(0.3)
                                : SparkTheme.cardBackground
                        )
                        .frame(height: 80)

                    Image(systemName: powerUp.iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(
                            powerUp.isPurchased
                                ? SparkTheme.mintGreen
                                : (canAfford ? SparkTheme.primaryText : SparkTheme.tertiaryText)
                        )
                }

                Text(powerUp.name)
                    .font(SparkTypography.caption(13))
                    .fontWeight(.semibold)
                    .foregroundStyle(SparkTheme.primaryText)
                    .lineLimit(1)

                if powerUp.isPurchased {
                    Text("Owned")
                        .font(SparkTypography.caption(11))
                        .foregroundStyle(SparkTheme.mintGreen)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text("\(powerUp.sparkCost)")
                            .font(SparkTypography.caption(12))
                    }
                    .foregroundStyle(canAfford ? SparkTheme.sunshineYellow : SparkTheme.tertiaryText)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SparkTheme.surfaceBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                powerUp.isPurchased
                                    ? SparkTheme.mintGreen.opacity(0.3)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .opacity(powerUp.isPurchased ? 0.7 : 1)
    }
}
