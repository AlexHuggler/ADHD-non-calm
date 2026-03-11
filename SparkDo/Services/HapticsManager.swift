import UIKit

enum HapticsManager {
    static var isEnabled = true

    static func buttonTap() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func wheelLanding() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    static func questComplete() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func levelUp() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        // Double success for level up
        generator.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            generator.notificationOccurred(.success)
        }
    }

    static func wheelTick() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func error() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}
