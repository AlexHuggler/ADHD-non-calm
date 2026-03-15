import SwiftUI

struct AnimatedCounter: View {
    let value: Int
    var prefix: String = ""
    var suffix: String = ""
    var font: Font = SparkTypography.heading(36)
    var color: Color = SparkTheme.primaryText

    var body: some View {
        HStack(spacing: 0) {
            if !prefix.isEmpty {
                Text(prefix)
                    .font(font)
                    .foregroundStyle(color)
            }

            Text("\(value)")
                .font(font)
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .monospacedDigit()

            if !suffix.isEmpty {
                Text(suffix)
                    .font(font)
                    .foregroundStyle(color)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prefix)\(value)\(suffix)")
    }
}

struct FloatingXPText: View {
    let amount: Int
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 14))
            Text("+\(amount)")
                .font(SparkTypography.subheading())
        }
        .foregroundStyle(SparkTheme.sunshineYellow)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                offset = -60
                opacity = 0
            }
        }
        .accessibilityLabel("Earned \(amount) sparks")
    }
}

#Preview {
    VStack(spacing: 20) {
        AnimatedCounter(value: 1250, suffix: " XP")
        FloatingXPText(amount: 25)
    }
    .padding()
    .background(SparkTheme.darkBackground)
}
