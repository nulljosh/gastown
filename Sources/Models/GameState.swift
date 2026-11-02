import Foundation

enum InputMode: String, Sendable {
    case normal, build, demolish
}

@Observable
@MainActor
final class GameState {
    var resources: [ResourceType: Int] = [
        .food: 30,
        .materials: 40,
        .power: 0
    ]
    var colonists: [ColonistModel] = []
    var buildings: [BuildingModel] = []
    var resourceNodes: [ResourceModel] = []
    var selectedColonistId: UUID?
    var isPaused: Bool = false
    var currentTick: Int = 0
    var currentHour: Int = 0
    var isNight: Bool = false
    var inputMode: InputMode = .normal
    var selectedBuildingType: BuildingType?
    var gameLog: [String] = []
    var showBuildMenu: Bool = false
    var showSettings: Bool = false

    // Multi-select
    var selectedColonistIds: Set<UUID> = []

    // Tutorial
    var tutorialStep: Int? = nil  // nil = done/skipped, 0-7 = active

    // Save system
    var lastSaveSlot: Int? = nil { didSet { saveCount += 1 } } // set on every successful save
    // Stored (so SwiftUI sees the switch flip) and kept across launches.
    var autoSaveEnabled: Bool = UserDefaults.standard.object(forKey: "autoSaveEnabled") as? Bool ?? true {
        didSet { if !isMenuBackdrop { UserDefaults.standard.set(autoSaveEnabled, forKey: "autoSaveEnabled") } }
    }
    /// Bumped on every successful save (through lastSaveSlot), so the settings slot list refreshes.
    var saveCount = 0
    var showSaveIndicator: Bool = false
    var victoryShown: Bool = false
    var victoryDismissed: Bool = false
    /// True only for the city running behind the title menu.
    var isMenuBackdrop: Bool = false

    // Audio
    // Stored rather than computed over UserDefaults: Observation only tracks stored properties.
    var soundEnabled: Bool = AudioManager.shared.soundEnabled {
        didSet { AudioManager.shared.soundEnabled = soundEnabled }
    }

    var selectedColonist: ColonistModel? {
        guard let id = selectedColonistId else { return nil }
        return colonists.first { $0.id == id }
    }

    func log(_ message: String) {
        gameLog.append(message)
        if gameLog.count > 50 {
            gameLog.removeFirst()
        }
    }
}
