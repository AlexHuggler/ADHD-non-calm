import SwiftUI

struct XPBadge: View {
    let value: Int
    var suffix: String = "XP"
    var size: BadgeSize = .small

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: 10
            case .medium: 12
            case .large: 14
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: 12
            case .medium: 13
            case .large: 16
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.system(size: size.iconSize))

            Text(suffix.isEmpty ? "\(value)" : "\(value) \(suffix)")
                .font(SparkTypography.caption(size.fontSize))
        }
        .foregroundStyle(SparkTheme.sunshineYellow)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(suffix.isEmpty ? "sparks" : suffix)")
    }
}

struct XPBadgePill: View {
    let value: Int
    var size: XPBadge.BadgeSize = .small

    var body: some View {
        XPBadge(value: value, suffix: "", size: size)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(SparkTheme.sunshineYellow.opacity(0.15))
            )
    }
}

#Preview {
    VStack(spacing: 16) {
        XPBadge(value: 25, size: .small)
        XPBadge(value: 50, size: .medium)
        XPBadge(value: 100, size: .large)
        XPBadgePill(value: 25)
    }
    .padding()
    .background(SparkTheme.darkBackground)
}
