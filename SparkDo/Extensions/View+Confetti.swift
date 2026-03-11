import SwiftUI

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var rotation: Angle
    var scale: CGFloat
    var opacity: Double
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let colors: [Color] = [
        SparkTheme.electricPurple,
        SparkTheme.coral,
        SparkTheme.sunshineYellow,
        SparkTheme.teal,
        SparkTheme.mintGreen,
    ]

    var body: some View {
        GeometryReader { geo in
            if reduceMotion {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(SparkTheme.mintGreen)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.5)
                    .animation(.easeOut(duration: 0.4), value: isAnimating)
            } else {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(particle.color)
                        .frame(width: 8, height: 12)
                        .scaleEffect(particle.scale)
                        .rotationEffect(particle.rotation)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
        }
        .onAppear {
            launchConfetti(in: geo.size)
        }
        .allowsHitTesting(false)
    }

    // H4 fix: Accept size from GeometryReader instead of using deprecated UIScreen.main
    private func launchConfetti(in size: CGSize) {
        guard !reduceMotion else {
            isAnimating = true
            return
        }

        let screenWidth = size.width
        let centerX = screenWidth / 2
        let centerY = size.height / 2

        for _ in 0..<40 {
            let particle = ConfettiParticle(
                position: CGPoint(x: centerX, y: centerY),
                color: colors.randomElement() ?? SparkTheme.electricPurple,
                rotation: .degrees(Double.random(in: 0...360)),
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: 1.0
            )
            particles.append(particle)
        }

        withAnimation(.easeOut(duration: 0.8)) {
            for i in particles.indices {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: 20...(screenWidth - 20)),
                    y: CGFloat.random(in: 50...size.height)
                )
                particles[i].rotation = .degrees(Double.random(in: 0...720))
                particles[i].opacity = 0
            }
        }

        // M2 fix: Use Task.sleep instead of DispatchQueue.main.asyncAfter
        Task {
            try? await Task.sleep(for: .milliseconds(900))
            particles.removeAll()
        }
    }
}

struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool

    func body(content: Content) -> some View {
        content.overlay {
            if isActive {
                ConfettiView()
                    .task {
                        // M2 fix: Use structured concurrency instead of DispatchQueue
                        try? await Task.sleep(for: .seconds(1))
                        isActive = false
                    }
            }
        }
    }
}

extension View {
    func confetti(isActive: Binding<Bool>) -> some View {
        modifier(ConfettiModifier(isActive: isActive))
    }
}
