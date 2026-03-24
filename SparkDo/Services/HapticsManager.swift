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

    static func streakRecord() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            let gen2 = UIImpactFeedbackGenerator(style: .heavy)
            gen2.impactOccurred()
            try? await Task.sleep(for: .milliseconds(100))
            let gen3 = UINotificationFeedbackGenerator()
            gen3.notificationOccurred(.success)
        }
    }

    static func purchaseSuccess() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            gen.impactOccurred()
        }
    }

    static func validationError() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    static func sprintTick() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.4)
    }

    static func challengeComplete() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        Task {
            try? await Task.sleep(for: .milliseconds(120))
            let gen2 = UIImpactFeedbackGenerator(style: .heavy)
            gen2.impactOccurred()
            try? await Task.sleep(for: .milliseconds(120))
            generator.notificationOccurred(.success)
        }
    }

    static func achievementUnlock() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            let gen2 = UIImpactFeedbackGenerator(style: .light)
            gen2.impactOccurred()
            try? await Task.sleep(for: .milliseconds(100))
            generator.impactOccurred()
            try? await Task.sleep(for: .milliseconds(100))
            let gen3 = UINotificationFeedbackGenerator()
            gen3.notificationOccurred(.success)
        }
    }

    static func undoAction() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}
