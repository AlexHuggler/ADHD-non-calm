import SwiftUI

enum SparkTheme {
    // MARK: - Primary Palette
    static let electricPurple = Color(hex: 0x6C5CE7)
    static let coral = Color(hex: 0xFF6B6B)
    static let sunshineYellow = Color(hex: 0xFECA57)
    static let teal = Color(hex: 0x54A0FF)
    static let mintGreen = Color(hex: 0x5CD859)

    // MARK: - Background
    static let darkBackground = Color(hex: 0x1A1A2E)
    static let cardBackground = Color(hex: 0x252541)
    static let surfaceBackground = Color(hex: 0x16213E)

    // MARK: - Text
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let tertiaryText = Color.white.opacity(0.4)

    // MARK: - Energy Colors
    static func energyColor(for level: EnergyLevel) -> Color {
        switch level {
        case .low: mintGreen
        case .medium: sunshineYellow
        case .high: coral
        }
    }

    // MARK: - Accent Colors Array (for variety)
    static let accentColors: [Color] = [
        electricPurple, coral, sunshineYellow, teal, mintGreen,
    ]

    static func randomAccent() -> Color {
        accentColors.randomElement() ?? electricPurple
    }

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [electricPurple, teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sparkGradient = LinearGradient(
        colors: [sunshineYellow, coral],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [darkBackground, surfaceBackground],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

// MARK: - Typography

enum SparkTypography {
    static func heading(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func subheading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func questCard() -> Font {
        .system(size: 18, weight: .semibold, design: .rounded)
    }
}

// MARK: - View Modifiers

struct SparkCardStyle: ViewModifier {
    var color: Color = SparkTheme.cardBackground

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct GlowEffect: ViewModifier {
    var color: Color = SparkTheme.electricPurple
    var radius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
    }
}

extension View {
    func sparkCard(color: Color = SparkTheme.cardBackground) -> some View {
        modifier(SparkCardStyle(color: color))
    }

    func glow(color: Color = SparkTheme.electricPurple, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}
