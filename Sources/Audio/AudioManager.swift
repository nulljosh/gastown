import AVFoundation
import AudioToolbox

/// Plays short system sounds for key game events.
/// Toggle via UserDefaults key "soundEnabled".
@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var mixer: AVAudioMixerNode?

    private init() {}

    var soundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "soundEnabled") }
    }

    // MARK: - Public API

    func buildingPlaced() {
        guard soundEnabled else { return }
        // Short high click -- system sound 1104 (key press)
        AudioServicesPlaySystemSound(1104)
    }

    func combatHit() {
        guard soundEnabled else { return }
        // Tock sound -- system sound 1105
        AudioServicesPlaySystemSound(1105)
    }

    func colonistDied() {
        guard soundEnabled else { return }
        // Low thud -- system sound 1073 (mail send whoosh, low)
        AudioServicesPlaySystemSound(1073)
    }
}
