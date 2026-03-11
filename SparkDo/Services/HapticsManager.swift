import UIKit

// H2 fix: @MainActor ensures isEnabled and all haptic calls are Main Thread only.
// M2 fix: Replace DispatchQueue.main.asyncAfter with Task.sleep.
@MainActor
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
        Task {
            try? await Task.sleep(for: .milliseconds(150))
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
