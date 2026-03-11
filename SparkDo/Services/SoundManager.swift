import AVFoundation

// H1 fix: Add @MainActor to ensure all mutable state (players dict, isEnabled)
// is accessed only from the Main Thread. All callers are UI-driven.
@MainActor
@Observable
final class SoundManager {
    static let shared = SoundManager()

    var isEnabled = true
    private var players: [String: AVAudioPlayer] = [:]

    enum Sound: String {
        case questComplete = "quest_complete"
        case levelUp = "level_up"
        case wheelTick = "wheel_tick"
        case wheelLand = "wheel_land"
        case sprintComplete = "sprint_complete"
        case rapidCaptureDing = "rapid_capture_ding"
        case sparkEarned = "spark_earned"
        case achievementUnlock = "achievement_unlock"
    }

    // M4 fix: Named constants for system sound IDs
    private enum SystemSounds {
        static let positiveTone: SystemSoundID = 1057
        static let celebrationTone: SystemSoundID = 1025
        static let tick: SystemSoundID = 1104
        static let thud: SystemSoundID = 1052
        static let ding: SystemSoundID = 1054
    }

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // M1 fix: Log audio session errors instead of silencing
            print("SparkDo [SoundManager]: Audio session setup failed: \(error)")
        }
    }

    func play(_ sound: Sound) {
        guard isEnabled else { return }

        // Check if we have a cached player
        if let player = players[sound.rawValue] {
            player.currentTime = 0
            player.play()
            return
        }

        // Try to load the sound file
        // Supports .caf, .wav, .mp3 formats
        let extensions = ["caf", "wav", "mp3"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: ext) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = 0.5
                    players[sound.rawValue] = player
                    player.play()
                    return
                } catch {
                    // M1 fix: Log load errors
                    print("SparkDo [SoundManager]: Failed to load \(sound.rawValue).\(ext): \(error)")
                    continue
                }
            }
        }

        // Sound file not found — use system sound fallback
        playSystemFallback(for: sound)
    }

    private func playSystemFallback(for sound: Sound) {
        let systemSoundID: SystemSoundID
        switch sound {
        case .questComplete, .sparkEarned:
            systemSoundID = SystemSounds.positiveTone
        case .levelUp, .sprintComplete, .achievementUnlock:
            systemSoundID = SystemSounds.celebrationTone
        case .wheelTick:
            systemSoundID = SystemSounds.tick
        case .wheelLand:
            systemSoundID = SystemSounds.thud
        case .rapidCaptureDing:
            systemSoundID = SystemSounds.ding
        }
        AudioServicesPlaySystemSound(systemSoundID)
    }

    func preloadSounds() {
        let commonSounds: [Sound] = [.questComplete, .wheelTick, .sparkEarned]
        for sound in commonSounds {
            let extensions = ["caf", "wav", "mp3"]
            for ext in extensions {
                if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: ext),
                   let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    players[sound.rawValue] = player
                    break
                }
            }
        }
    }
}
