import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    var color: Color
    var duration: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    LinearGradient(
                        colors: [
                            .clear,
                            color.opacity(0.3),
                            color.opacity(0.5),
                            color.opacity(0.3),
                            .clear,
                        ],
                        startPoint: .init(x: phase - 0.5, y: 0.5),
                        endPoint: .init(x: phase + 0.5, y: 0.5)
                    )
                    .blendMode(.overlay)
                    .onAppear {
                        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                            phase = 1.5
                        }
                    }
                }
            }
            .clipped()
    }
}

struct PulseGlowModifier: ViewModifier {
    @State private var isGlowing = false
    var color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isGlowing ? 0.6 : 0.2),
                radius: isGlowing ? 15 : 5,
                x: 0,
                y: 0
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

extension View {
    func shimmer(color: Color = .white, duration: Double = 2.0) -> some View {
        modifier(ShimmerModifier(color: color, duration: duration))
    }

    func pulseGlow(color: Color = SparkTheme.electricPurple) -> some View {
        modifier(PulseGlowModifier(color: color))
    }
}
