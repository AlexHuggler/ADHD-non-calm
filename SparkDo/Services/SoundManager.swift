import AVFoundation

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

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session configuration is best-effort
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
            systemSoundID = 1057 // short positive tone
        case .levelUp, .sprintComplete, .achievementUnlock:
            systemSoundID = 1025 // celebration-like tone
        case .wheelTick:
            systemSoundID = 1104 // tick
        case .wheelLand:
            systemSoundID = 1052 // thud
        case .rapidCaptureDing:
            systemSoundID = 1054 // ding
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
