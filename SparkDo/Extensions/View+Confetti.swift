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
            launchConfetti()
        }
        .allowsHitTesting(false)
    }

    private func launchConfetti() {
        guard !reduceMotion else {
            isAnimating = true
            return
        }

        let screenWidth: CGFloat = UIScreen.main.bounds.width
        let centerX = screenWidth / 2
        let centerY: CGFloat = 300

        for _ in 0..<40 {
            let particle = ConfettiParticle(
                position: CGPoint(x: centerX, y: centerY),
                color: colors.randomElement()!,
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
                    y: CGFloat.random(in: 50...600)
                )
                particles[i].rotation = .degrees(Double.random(in: 0...720))
                particles[i].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
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
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isActive = false
                        }
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
